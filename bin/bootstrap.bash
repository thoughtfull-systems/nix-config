#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ############################
set -euo pipefail

function log { echo "=== ${1}"; }

log "Installation starting $(date)"

## VERIFY ##
function die { echo "!!! ${1}" >&2; exit 1; }

[[ -v 1 ]] || die "Expected hostname as first argument"
hostname="${1}"

boot_part="${hostname}-boot"
boot_device="/dev/disk/by-partlabel/${boot_part}"
[[ -b "${boot_device}" ]] ||
  die "Missing partition ${boot_part}"

luks_part="${hostname}-luks"
luks_device="/dev/disk/by-partlabel/${luks_part}"
[[ -b "${luks_device}" ]] ||
  die "Missing parttion ${luks_part}"

lvm_name="${hostname}-lvm"
lvm_device="/dev/mapper/${lvm_name}"

function ask_no_echo() {
  msg="??? ${1} "
  read -sp "${msg}" ${2}
  # prevents bunching in the log (because input is not logged)
  echo
}

function indent { sed -E 's/\r$//g;s/\r/\n/g' | sed -E "s/^/    /g"; }

function wait_for() {
  if [[ ! -e "${1}" ]] &>/dev/null; then
    log "Waiting for '${1}'..."
    while [[ ! -e "${1}" ]] &>/dev/null; do
      sleep 1
    done
  fi
}

if [[ ! -b "${lvm_device}" ]]; then
  ask_no_echo "Enter passphrase for ${luks_device}:" PASS
  while ! echo "${PASS}" |
      cryptsetup open "${luks_device}" "${lvm_name}" |& indent; do
    echo "Open LUKS failed!"
    ask_no_echo "Enter passphrase for ${luks_device}:" PASS
  done
  wait_for "/dev/mapper/${lvm_name}"
fi

pvs | grep "${lvm_device}" &>/dev/null || die "Missing physical volume ${lvm_device}"

vg_name="${hostname}"
vgs | grep "${vg_name}" &>/dev/null || die "Missing volume group ${vg_name}"

function verify_lv {
  lvs -S "vg_name=${vg_name} && lv_name=${1}" |
    grep "${1}" &>/dev/null || die "Missing logical volume ${1}"
}

verify_lv "root"
verify_lv "swap"

## MOUNT ##
function is_mounted {
  mount | grep " ${1} " &>/dev/null
}

is_mounted "/mnt" ||
  mount "/dev/mapper/${hostname}-root" "/mnt" |& indent
is_mounted "/mnt/boot" ||
  mount "${boot_device}" "/mnt/boot" |& indent

swap_device="/dev/mapper/${hostname}-swap"
swapon | grep "$(realpath ${swap_device})" &>/dev/null ||
  swapon "${swap_device}" |& indent

## GENERATE ##
# copied from sshd pre-start script
ssh_dir="/mnt/etc/ssh"
if ! [ -s "${ssh_dir}/ssh_host_rsa_key" ]; then
  if ! [ -h "${ssh_dir}/ssh_host_rsa_key" ]; then
    rm -f "${ssh_dir}/ssh_host_rsa_key" |& indent
  fi
  log "Generating openssh host rsa keys"
  mkdir -m 0755 -p "$(dirname '${ssh_dir}/ssh_host_rsa_key')" |& indent
  ssh-keygen -t "rsa" -b 4096 -C "root@${hostname}" -f "${ssh_dir}/ssh_host_rsa_key" -N "" |& indent
fi
keypath="${ssh_dir}/ssh_host_ed25519_key"
if ! [ -s "${keypath}" ]; then
  if ! [ -h "${keypath}" ]; then
    rm -f "${keypath}" |& indent
  fi
  log "Generating openssh host ed25519 keys"
  mkdir -m 0755 -p "$(dirname '${keypath}')" |& indent
  ssh-keygen -t "ed25519" -C "root@${hostname}" -f "${keypath}" -N "" |& indent
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

ssh-keygen -t "rsa" -b 4096 -N ""

## COPY LOG ##
log "Copying log file"
log "Installation complete $(date)"
cp "${logfile}" "/mnt/etc/nixos/bootstrap.log"
