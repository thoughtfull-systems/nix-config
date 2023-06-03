#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ############################
set -euo pipefail

function log { printf "%s === %s\n" "$(date -uIns)" "${1}"; }
function die { printf "%s !!! %s\n" "$(date -uIns)" "${1}" >&2; exit 1; }
function indent {
  while read -r line; do
    printf '    %s\n' "${line}";
  done
}
function try {
  out=$(mktemp)
  if ! (eval "${1}") &>${out}; then
    result=$?
    cat ${out} | indent
    rm ${out}
    return $result
  else
    rm ${out}
    return 0
  fi
}
function ask_no_echo() {
  msg="??? ${1} "
  read -sp "${msg}" ${2}
  # prevents bunching in the log (because input is not logged)
  echo
}
function wait_for() {
  if [[ ! -e "${1}" ]] &>/dev/null; then
    log "Waiting for: ${1}"
    while [[ ! -e "${1}" ]] &>/dev/null; do
      sleep 1
    done
  fi
  log "Exists: ${1}"
}
function verify_partition {
  [[ -b "/dev/disk/by-partlabel/${1}" ]] ||
    die "Partition missing: ${1}"
  log "Patition exists: ${1}"
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
function verify_logical_volume {
  try "lvs -S 'vg_name=${vg_name} && lv_name=${1}' | grep '${1}'" ||
    die "Logical volume missing: ${1}"
  log "Logical volume exists: ${1}"
}
function verify_disks {
  verify_partition "${boot_name}"
  verify_partition "${luks_name}"
  open_luks_device

  try "pvs | grep '${lvm_device}'" || die "Physical volume missing: ${lvm_device}"
  log "Physical volume exists: ${lvm_device}"

  try "vgs | grep '${vg_name}'" || die "Volume group missing: ${vg_name}"
  log "Volume group exists: ${vg_name}"

  verify_logical_volume "root"
  verify_logical_volume "swap"
}
function is_mounted {
  try "mount | grep ' ${1} '"
}
function mount_partition {
  try "is_mounted '${2}' || mount '${1}' '${2}'" ||
    die "Failed to mount '${1}'"
  log "Mounted: ${2}"
}
function enable_swap {
  try "swapon | grep '$(realpath ${swap_device})' || swapon '${swap_device}'" ||
    die "Failed to enable swap ${swap_device}"
  log "Swap enabled: ${swap_device}"
}
function create_ssh_keys {
  # copied from sshd pre-start script
  try "mkdir -m 0755 -p '${ssh_dir}'"
  sshargs="-C 'root@${hostname}' -N ''"
  if ! [ -s "${rsa_key_path}" ]; then
    if ! [ -h "${rsa_key_path}" ]; then
      try "rm -f '${rsa_key_path}'"
    fi
    try "ssh-keygen -t 'rsa' -b 4096 -f '${rsa_key_path}' ${sshargs}" ||
      die "Failed to generate host RSA keys"
    log "Generated host RSA keys"
  fi
  if ! [ -s "${ed25519_key_path}" ]; then
    if ! [ -h "${ed25519_key_path}" ]; then
      try "rm -f '${ed25519_key_path}'"
    fi
    try "ssh-keygen -t 'ed25519' -f '${ed25519_key_path}' ${sshargs}" ||
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
  log "${ed25519_key_path}.pub"
  echo -e "\n>>>>>"
  cat "${ed25519_key_path}.pub"
  echo -e "<<<<<\n"
  log "hardware-configuration.nix"
  echo -e "\n>>>>>"
  nixos-generate-config --show-hardware-config --no-filesystems
  echo -e "<<<<<\n"
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
verify_disks
mount_partition "/dev/mapper/${hostname}-root" "/mnt"
try "mkdir -p '/mnt/boot'"
mount_partition "${boot_device}" "/mnt/boot"
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
