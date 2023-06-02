#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ############################
set -euo pipefail

function log { printf "%s === %s\n" "$(date -uIns)" "${1}"; }
function die { printf "%s !!! %s\n" "$(date -uIns)" "${1}" >&2; exit 1; }
function try {
  out=$(mktemp)
  if ! (eval "${1}") &>${out}; then
    result=$?
    cat ${out}
    rm ${out}
    return $result
  else
    rm ${out}
    return 0
  fi
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
function verify_partition {
  [[ -b "/dev/disk/by-partlabel/${1}" ]] ||
    die "Missing partition: ${1}"
  log "Verified \"${1}\" partition"
}
function open_luks_device {
  if [[ ! -b "${lvm_device}" ]]; then
    ask_no_echo "Enter passphrase for ${luks_device}:" PASS
    while ! echo "${PASS}" |
        cryptsetup open "${luks_device}" "${lvm_name}" |& indent; do
      echo "Open LUKS failed!" | indent
      ask_no_echo "Enter passphrase for ${luks_device}:" PASS
    done
    wait_for "${lvm_device}"
  fi
  log "Opened LUKS device \"${luks_device}\""
}
function verify_lv {
  try "lvs -S \"vg_name=${vg_name} && lv_name=${1}\" | grep \"${1}\"" |& indent ||
    die "Missing logical volume: ${1}"
  log "Verified \"${1}\" volume"
}
function verify_disks {
  verify_partition "${boot_name}"
  verify_partition "${luks_name}"
  open_luks_device

  try "pvs | grep \"${lvm_device}\"" | indent || die "Missing physical volume: ${lvm_device}"
  log "Verified \"${lvm_device}\" physical volume"

  try "vgs | grep \"${vg_name}\"" | indent || die "Missing volume group: ${vg_name}"
  log "Verified \"${vg_name}\" volume group"

  verify_lv "root"
  verify_lv "swap"
  log "Verified disks"
}
function is_mounted {
  try "mount | grep \" ${1} \"" | indent
}
function ensure_mnt {
  try "is_mounted \"${2}\" || mount \"${1}\" \"${2}\"" | indent ||
    die "Failed to mount \"${1}\""
  log "Mounted \"${2}\""
}
function ensure_swap {
  try "swapon | grep \"$(realpath ${swap_device})\" || swapon \"${swap_device}\"" | indent ||
    die "Failed to enable swap ${swap_device}"
  log "Enabled swap \"${swap_device}\""
}
function ensure_ssh_keys {
  # copied from sshd pre-start script
  ssh_dir="/mnt/etc/ssh"
  mkdir -m 0755 -p "${ssh_dir}" |& indent
  keypath="${ssh_dir}/ssh_host_rsa_key"
  sshargs="-C \"root@${hostname}\" -N \"\""
  if ! [ -s "${keypath}" ]; then
    if ! [ -h "${keypath}" ]; then
      try "rm -f \"${keypath}\"" |& indent
    fi
    log "Generating openssh host rsa keys"
    try "ssh-keygen -t \"rsa\" -b 4096 -f \"${keypath}\" ${sshargs}" |& indent ||
      die "Failed to generate host RSA key"
  fi
  keypath="${ssh_dir}/ssh_host_ed25519_key"
  if ! [ -s "${keypath}" ]; then
    if ! [ -h "${keypath}" ]; then
      try "rm -f \"${keypath}\"" |& indent
    fi
    log "Generating openssh host ed25519 keys"
    try "ssh-keygen -t \"ed25519\" -f \"${keypath}\" ${sshargs}" |& indent ||
      die "Failed to generate host ed25519"
  fi
  log "Verified SSH keys exist"
}
function pause_for_input {
  read -sp "Press any key to continue..."
  echo
}
function print_key_and_config {
  log "${keypath}.pub"
  cat "${keypath}.pub"
  log "hardware-configuration.nix"
  nixos-generate-config --show-hardware-config --no-filesystems
  log "Add these for ${hostname}, rekey secrets, and commit"
  pause_for_input
}

log "Installation started"
[[ -v 1 ]] || die "Expected hostname as first argument"
log "Using hostname ${hostname}"
repo="${2:-github:thoughtfull-systems/nix-config}"
log "Using repo ${repo}"
pause_for_input
hostname="${1}"
luks_name="${hostname}-luks"
luks_device="/dev/disk/by-partlabel/${luks_name}"
lvm_name="${hostname}-lvm"
lvm_device="/dev/mapper/${lvm_name}"
vg_name="${hostname}"
swap_device="/dev/mapper/${hostname}-swap"
boot_name="${hostname}-boot"
boot_device="/dev/disk/by-partlabel/${boot_name}"
verify_disks
ensure_mnt "/dev/mapper/${hostname}-root" "/mnt"
try "mkdir -p \"/mnt/boot\"" | indent
ensure_mnt "${boot_device}" "/mnt/boot"
ensure_swap
ensure_ssh_keys
print_key_and_config

nixos-install --no-root-password --flake "${repo}#${hostname}" |& indent ||
  die "Failed to install NixOS"

log "Copying log file"
log "Installation complete"
cat "${logfile}" >> "/mnt/etc/nixos/bootstrap.log"
