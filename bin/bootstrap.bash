#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ############################
set -euo pipefail

function log { printf "%s === %s\n" "$(date -uIns)" "${1}"; }
function die { printf "%s !!! %s\n" "$(date -uIns)" "${1}" >&2; exit 1; }
function ts {
  while read -r line; do
    printf '%s %s\n' "$(date -uIns)" "${line}";
  done
}
function try_ts {
  # a bit complicated, but captures both stdout and stderr in (pretty much) printed order, and
  # displays only stdout on success and both stdout and stderr on failure.
  out=$(mktemp)
  err=$(mktemp)
  dir=$(mktemp -d)
  # the fifos are necessary so we can have some subprocess for which to wait, otherwise the outputs
  # aren't ready when we try to cat them
  outp="${dir}/out"
  mkfifo ${outp}
  (cat ${outp} >${out}) &
  outpid=$!
  errp="${dir}/err"
  mkfifo ${errp}
  (cat ${errp} >${err}) &
  errpid=$!
  if (eval "${1}") 1> >(ts > ${outp}) 2> >(ts > ${errp}); then
    wait ${outpid} ${errpid}; rm -rf "${dir}"
    cat ${out} | sort
    rm ${out} ${err}
  else
    result=$?
    wait ${outpid} ${errpid}; rm -rf "${dir}"
    cat ${out} ${err} | sort
    rm ${out} ${err}
    return $result
  fi
}
function try {
  # cut off the timestamp at the beginning of each line
  run_ts "${1}" > >(cut -c 37-)
}
function indent {
  while read -r line; do
    printf '    %s\n' "${line}";
  done
}
function ask_no_echo() {
  msg="??? ${1} "
  read -sp "${msg}" ${2}
  # prevents bunching in the log (because input is not logged)
  echo
}
function wait_for() {
  if [[ ! -e "${1}" ]] &>/dev/null; then
    log "Waiting for '${1}'..."
    while [[ ! -e "${1}" ]] &>/dev/null; do
      sleep 1
    done
  fi
}


log "Installation started"

## VERIFY ##

[[ -v 1 ]] || die "Expected hostname as first argument"
hostname="${1}"

boot_part="${hostname}-boot"
boot_device="/dev/disk/by-partlabel/${boot_part}"
[[ -b "${boot_device}" ]] ||
  die "Missing partition: ${boot_part}"

luks_part="${hostname}-luks"
luks_device="/dev/disk/by-partlabel/${luks_part}"
[[ -b "${luks_device}" ]] ||
  die "Missing partition: ${luks_part}"

lvm_name="${hostname}-lvm"
lvm_device="/dev/mapper/${lvm_name}"

log "Opening LVM device: ${lvm_device}"
if [[ ! -b "${lvm_device}" ]]; then
  ask_no_echo "Enter passphrase for ${luks_device}:" PASS
  while ! echo "${PASS}" |
      cryptsetup open "${luks_device}" "${lvm_name}" |& indent; do
    echo "Open LUKS failed!"
    ask_no_echo "Enter passphrase for ${luks_device}:" PASS
  done
  wait_for "/dev/mapper/${lvm_name}"
fi

(pvs | grep "${lvm_device}") &>/dev/null || die "Missing physical volume: ${lvm_device}"

vg_name="${hostname}"
(vgs | grep "${vg_name}") &>/dev/null || die "Missing volume group: ${vg_name}"

function verify_lv {
  try <<-EOF || die "Missing logical volume: ${1}"
    lvs -S "vg_name=${vg_name} && lv_name=${1}" | grep "${1}"
EOF
}

verify_lv "root"
verify_lv "swap"

## MOUNT ##
function is_mounted {
  (mount | grep " ${1} ") &>/dev/null
}

is_mounted "/mnt" ||
  mount "/dev/mapper/${hostname}-root" "/mnt" |& indent ||
  die "Failed to mount /dev/mapper/${hostname}-root"
is_mounted "/mnt/boot" ||
  mount "${boot_device}" "/mnt/boot" |& indent ||
  die "Failed to mount ${boot_device}"

swap_device="/dev/mapper/${hostname}-swap"
(swapon | grep "$(realpath ${swap_device})") &>/dev/null ||
  swapon "${swap_device}" |& indent ||
  die "Failed to enable swap ${swap_device}"

## GENERATE ##
# copied from sshd pre-start script
ssh_dir="/mnt/etc/ssh"
if ! [ -s "${ssh_dir}/ssh_host_rsa_key" ]; then
  if ! [ -h "${ssh_dir}/ssh_host_rsa_key" ]; then
    rm -f "${ssh_dir}/ssh_host_rsa_key" |& indent
  fi
  log "Generating openssh host rsa keys"
  (mkdir -m 0755 -p "$(dirname '${ssh_dir}/ssh_host_rsa_key')" |& indent
   ssh-keygen -t "rsa" -b 4096 -C "root@${hostname}" -f "${ssh_dir}/ssh_host_rsa_key" -N "" |&
   indent) ||
    die "Failed to generate host RSA key"
fi
keypath="${ssh_dir}/ssh_host_ed25519_key"
if ! [ -s "${keypath}" ]; then
  if ! [ -h "${keypath}" ]; then
    rm -f "${keypath}" |& indent
  fi
  log "Generating openssh host ed25519 keys"
  (mkdir -m 0755 -p "$(dirname '${keypath}')" |& indent
   ssh-keygen -t "ed25519" -C "root@${hostname}" -f "${keypath}" -N "" |& indent) ||
    die "Failed to generate host ed25519"
fi

log "${keypath}.pub"
cat "${keypath}.pub"
log "hardware-configuration.nix"
nixos-generate-config --show-hardware-config --no-filesystems
log "Add these for ${hostname}, rekey secrets, and commit"
read -sp "Press any key to continue..."
echo

## INSTALL ##
repo="${2:-github:thoughtfull-systems/nix-config}"
nixos-install --no-root-password --flake "${repo}#${hostname}" |& indent ||
  die "Failed to install NixOS"

## COPY LOG ##
log "Copying log file"
log "Installation complete $(date)"
cat "${logfile}" >> "/mnt/etc/nixos/bootstrap.log"
