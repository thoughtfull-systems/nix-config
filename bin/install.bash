#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ############################
set -euo pipefail

function log { printf "%s === %s\n" "$(date -uIns)" "${1}"; }
function die { printf "%s !!! %s\n" "$(date -uIns)" "${1}" >&2; exit 1; }
function indent { sed -E 's/\r$//g;s/\r/\n/g' | sed -E "s/^/    /g"; }
function ask_no_echo() {
  read -sp "${1}" "${2}"
  # prevents bunching in the log (because input is not logged)
  echo
}
function is_mounted {
  (mount | grep " ${1} ") |& indent
}
function mount_partition {
  (is_mounted "${2}" || mount "${1}" "${2}") |& indent ||
    die "Failed to mount: ${1}"
  log "Mounted: ${2}"
}
function verify_partition {
  [[ -b "/dev/disk/by-partlabel/${1}" ]] ||
    die "Partition missing: ${1}"
  log "Partition exists: ${1}"
}
function verify_luks_device {
  if ! cryptsetup isLuks "${luks_device}" |& indent; then
    die "Invalid LUKS device: ${luks_device}"
  fi
  log "Valid LUKS device: ${luks_device}"
}
function wait_for() {
  if [[ ! -e "${1}" ]] &>/dev/null; then
    log "Waiting for: ${1}"
    while [[ ! -e "${1}" ]] &>/dev/null; do
      sleep 1
    done
  fi
  log "Found: ${1}"
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
  log "LUKS device opened: ${luks_device}"
}
function verify_physical_volume {
  if ! (pvs 2>/dev/null | grep "${lvm_device}") |& indent; then
    die "Physical volume missing: ${lvm_device}"
  fi
  log "Physical volume exists: ${lvm_device}"
}
function verify_volume_group {
  if ! (vgs 2>/dev/null | grep "${vg_name}") |& indent; then
    die "Volume group missing: ${vg_name}"
  fi
  log "Volume group exists: ${vg_name}"
}
function verify_logical_volume {
  if ! (lvs -S "vg_name=${vg_name} && lv_name=${1}" 2>/dev/null | grep "${1}") |& indent; then
    die "Logical volume missing: ${1}"
  fi
  log "Logical volume exists: ${1}"
}
function file {
  nix-shell -p file --run "file -sL ${1}"
}
function verify_ext4_device {
  if ! (file "${1}" | grep "ext4 filesystem") |& indent; then
    die "Invalid ext4 partition: ${1}"
  fi
  log "Valid ext4 partition: ${1}"
}
function verify_swap_device {
  if ! swaplabel "${swap_device}" |& indent; then
    die "Invalid swap device: ${swap_device}"
  fi
  log "Valid swap device: ${1}"
}
function verify_lvm_volumes {
  verify_physical_volume
  verify_volume_group
  verify_logical_volume "root"
  verify_ext4_device "${root_device}"
  verify_logical_volume "swap"
  verify_swap_volume
}
function verify_mnt {
  if ! is_mounted "/mnt"; then
    verify_partition "${luks_name}"
    verify_luks_device
    open_luks_device
    verify_lvm_volumes
    mount_partition "${root_device}" "/mnt"
  fi
}
function verify_boot {
  if ! is_mounted "/mnt/boot" |& indent; then
    verify_partition "${boot_name}"
    verify_ext4_device "${boot_device}"
    mkdir -p "/mnt/boot" |& indent
    mount_partition "${boot_device}" "/mnt/boot"
  fi
}
function enable_swap {
  if ! (swapon | grep "$(realpath ${swap_device})") &>/dev/null; then
    swapon "${swap_device}" |& indent || die "Failed to enable swap: ${swap_device}"
  fi
  log "Swap enabled: ${swap_device}"
}
function create_ssh_keys {
  # copied from sshd pre-start script
  mkdir -m 0755 -p "${ssh_dir}" |& indent
  if ! [ -s "${rsa_key_path}" ]; then
    if ! [ -h "${rsa_key_path}" ]; then
      rm -f "${rsa_key_path}" |& indent
    fi
    ssh-keygen -t "rsa" -b 4096 -f "${rsa_key_path}" -N "" -C "root@${hostname}" |& indent ||
      die "Failed to generate host RSA keys"
    log "Generated host RSA keys"
  fi
  if ! [ -s "${ed25519_key_path}" ]; then
    if ! [ -h "${ed25519_key_path}" ]; then
      rm -f "${ed25519_key_path}" |& indent
    fi
    ssh-keygen -t "ed25519" -f "${ed25519_key_path}" -N "" -C "root@${hostname}" |& indent ||
      die "Failed to generate host ed25519 keys"
    log "Generated host ed25519 keys"
  fi
  log "SSH host keys exist"
}
function pause_for_input {
  read -sp "Press any key to continue..."
  echo
}
function print_key_and_config {
  log "${ed25519_key_path}.pub >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  cat "${ed25519_key_path}.pub"
  log "hardware-configuration.nix >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  nixos-generate-config --show-hardware-config --no-filesystems
  log "Add these for ${hostname}, rekey secrets, and commit"
  pause_for_input
}

log "Installation started"
[[ -v 1 ]] || die "Expected hostname as first argument"
hostname="${1}"
log "Using hostname: ${hostname}"
repo="${2:-github:thoughtfull-systems/nix-config}"
log "Using repo: ${repo}"
pause_for_input

luks_name="${hostname}-luks"
luks_device="/dev/disk/by-partlabel/${luks_name}"
lvm_name="${hostname}-lvm"
lvm_device="/dev/mapper/${lvm_name}"
vg_name="${hostname}"
swap_device="/dev/mapper/${hostname}-swap"
boot_name="${hostname}-boot"
boot_device="/dev/disk/by-partlabel/${boot_name}"
root_device="/dev/disk/by-partlabel/${hostname}-root"
verify_mnt
verify_boot
enable_swap
ssh_dir="/mnt/etc/ssh"
rsa_key_path="${ssh_dir}/ssh_host_rsa_key"
ed25519_key_path="${ssh_dir}/ssh_host_ed25519_key"
create_ssh_keys
print_key_and_config

nixos-install --no-root-password --flake "${repo}#${hostname}" |& indent ||
  die "Failed to install NixOS"

log "Installation complete"
cat "${logfile}" >> "/mnt/etc/nixos/install.log"
rm "${logfile}"
