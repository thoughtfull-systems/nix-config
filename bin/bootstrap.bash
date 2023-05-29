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
[[ "${1}" = "$(hostname)" ]] || die "First argument does not match hostname"
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
  PASS=1
  CONFIRM=2
  while [[ "${PASS}" != "${CONFIRM}" ]]; do
    echo "Passphrases did not match!"
    ask_no_echo "Enter passphrase for ${luks_device}:" PASS
    ask_no_echo "Confirm passphrase for ${luks_device}:" CONFIRM
  done
  echo "${PASS}" |
    cryptsetup open "${luks_device}" "${lvm_name}" |& indent ||
    die "Failed to open '${luks_device}'"
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

## INSTALL ##
log "Generating hardware-configuration.nix"
log "Add this for ${hostname} and commit"
nixos-generate-config --show-hardware-config --no-filesystems
read -sp "Press any key to continue..."
echo

repo="${2:-github:thoughtfull-systems/nix-config}"
nixos-install --no-root-password --flake "${repo}#${hostname}" |& indent ||
  die "Failed to install NixOS"

## COPY LOG ##
log "Copying log file"
log "Installation complete $(date)"
cp "${logfile}" "/mnt/etc/nixos/bootstrap.log"
