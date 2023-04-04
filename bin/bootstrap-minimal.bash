#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ############################
set -euo pipefail

function die { echo "!!! ${1}" >&2; exit 1; }
function log { echo "=== ${1}"; }

log "Installation starting $(date)"

function ask() {
  msg="??? ${1} "
  if [[ -v 2 ]]; then
    read -p "${msg}" ${2}
  else
    read -p "${msg}"
  fi
  # prevents bunching in the log (because input is not logged)
  echo
}

function confirm {
  ask "${1} (y/N)"
  [[ ${REPLY} =~ ^[Yy].* ]]
}

nix="nix --extra-experimental-features nix-command \
         --extra-experimental-features flakes"
git="${nix} run nixpkgs#git --"

# Verify git working dir is clean
if output=$(${git} status --porcelain 2>/dev/null) && [[ -z "${output}" ]]; then
  log "Working directory is clean"
else
  die "Working directory is dirty"
fi

# Validate hostname argument
[[ -v 1 ]] || die "Expected hostname as first argument"
hostname="${1}"

function indent { sed -E 's/\r$//g;s/\r/\n/g' | sed -E "s/^/    /g"; }

# Checkout hostname branch?
function pull_latest {
  log "Fetching latest from origin"
  ${git} pull |& indent ||
    die "Failed fetching latest from origin"
  log "Working directory up-to-date"
}
if (${git} branch -a | grep "${hostname}") &>/dev/null &&
     [[ $(${git} branch --show-current 2>/dev/null) != "${hostname}" ]] &&
     confirm "Checkout '${hostname}' branch?"
then
  log "Checking out '${hostname}' branch"
  ${git} checkout ${hostname} |& indent ||
    die "Failed to checkout '${hostname}' branch"
  pull_latest
  log "Exec'ing new script"
  exec $(realpath ${0}) "${@}" ||
    die "Failed to exec new script"
else
  log "Remaining on current branch"
  pull_latest
fi
### SCRIPT IS RELOADED #########################################################
scriptdir="$(dirname $(realpath ${0}))"

# Validate ip argument
([[ -v 2 ]] && (ping -c1 "${2}" &>/dev/null)) ||
  die "Expected IP address as second argument"
ip="${2}"

repo="${3:-https://github.com/thoughtfull-systems/nix-config}"

### VARIABLES ##################################################################
# programs
ssh="ssh nixos@${ip} -q"
file="${nix} run nixpkgs#file -- -sL"
agenix="${nix} run github:ryantm/agenix --"

# devices
boot_name="${hostname}-boot"
boot_device="/dev/disk/by-partlabel/${boot_name}"
luks_name="${hostname}-lvm-luks"
luks_device="/dev/disk/by-partlabel/${luks_name}"
lvm_name="${hostname}-lvm"
lvm_device="/dev/mapper/${lvm_name}"
vg_name="${hostname}"
swap_device="/dev/mapper/${vg_name}-swap"
root_device="/dev/mapper/${vg_name}-root"

### FUNCTIONS ##################################################################
# General
function ask_no_echo() {
  msg="??? ${1} "
  read -sp "${msg}" ${2}
  # prevents bunching in the log (because input is not logged)
  echo
}

function really_sure {
  echo "??? Are your REALLY sure you want to ${1}? (ALL DATA WILL BE LOST)"
  ask "(Please enter YES in all caps):"

  [[ $REPLY = "YES" ]]
}

# Partitions & devices
function has_device {
  ${ssh} "[[ -b \"${1}\" ]]" &>/dev/null
}

function has_partition {
  has_device "/dev/disk/by-partlabel/${1}"
}

function is_mounted {
  ${ssh} mount \| grep \""${1}"\" &>/dev/null
}

function ensure_unmounted {
  if is_mounted "${1}"; then
    log "Unmounting '${1}'"
    ${ssh} sudo umount "${1}" |& indent
  fi
  if is_mounted "\$(realpath ${1})"; then
    log "Unmounting '${1}'"
    ${ssh} sudo umount "\$(realpath ${1})" |& indent
  fi
}

function ensure_mounted {
  if ! is_mounted "${1}" && ! is_mounted "\$(realpath ${1})"; then
    log "Mounting '${1}' to '${2}'"
    (${ssh} sudo mount "${1}" "${2}" 2>/dev/null ||
       ${ssh} sudo mount "\$(realpath ${1})" "${2}") |& indent ||
      die "Failed to mount '${1}'"
  fi
}

# LUKS
function is_luks { ${ssh} sudo cryptsetup isLuks "${luks_device}"; }

function wait_for() {
  if ${ssh} "[[ ! -e \"${1}\" ]]" &>/dev/null; then
    log "Waiting for '${1}'..."
    while ${ssh} "[[ ! -e \"${1}\" ]]" &>/dev/null; do
      sleep 1
    done
  fi
}

function ensure_luks_closed {
  if has_device "${lvm_device}"; then
    log "Closing LUKS device '${lvm_device}'"
    ${ssh} sudo cryptsetup close "${lvm_device}"
  fi
}

function open_luks {
  log "Using LUKS device '${luks_device}'"
  log "Opening LUKS device '${luks_device}' as '${lvm_name}'"
  # echo "${1}" |
  #   ${ssh} -t sudo cryptsetup open "${luks_device}" "${lvm_name}" |&
  #   indent ||
  #   die "Failed to open '${luks_device}'"
  ${ssh} -t sudo cryptsetup open "${luks_device}" "${lvm_name}" |&
  indent ||
    die "Failed to open '${luks_device}'"
  wait_for "/dev/mapper/${lvm_name}"
}

# LVM
function has_pv {
  ${ssh} sudo pvs | grep "${lvm_device}" &>/dev/null
}

function ensure_pv_removed {
  if has_pv; then
    log "Removing physical volume '${lvm_device}'"
    ${ssh} sudo pvremove -y "${lvm_device}" |& indent
  fi
}

function has_vg {
  ${ssh} sudo vgs | grep "${vg_name}" &>/dev/null
}

function ensure_vg_removed {
  if has_vg; then
    log "Removing volume group '${vg_name}'"
    ${ssh} sudo vgremove -y "${vg_name}"
  fi
}

function has_lv {
  ${ssh} sudo lvs -S "vg_name=${vg_name} && lv_name=${1}" | \
    grep "${1}" &>/dev/null
}

function ensure_lv_removed {
  if has_lv "${1}"; then
    log "Removing volume '${1}'"
    ${ssh} sudo lvremove -y "${vg_name}/${1}" |& indent
  fi
}

# FAT32
function is_boot_fat32 {
  (${ssh} sudo ${file} "${boot_device}" | grep "FAT (32 bit)") &>/dev/null
}

# Swap
function is_swap {
  ${ssh} sudo swaplabel "${swap_device}" &>/dev/null
}

function is_swapon {
  ${ssh} sudo swapon \| grep "\$(realpath ${swap_device})" &>/dev/null
}

function ensure_swapoff {
  if is_swapon; then
    ${ssh} sudo swapoff "\$(realpath ${swap_device})" |& indent ||
      die "Failed to disable swap '${swap_device}'"
  fi
}

function is_root_ext4 {
  ${ssh} sudo ${file} -sL "${root_device}" | grep "ext4 filesystem" &>/dev/null
}

function was_partitioned {
  [[ ${partitioned} -eq 0 ]]
}

### SETUP ######################################################################
# Confirm ssh access to machine
log "Checking ssh access to machine"
if ssh nixos@${ip} : ; then
  log "Confirmed SSH access to machine"
else
  die "Set up SSH access to '${ip}' (either password or public key)"
fi

### PARTITION TABLE ###
${ssh} sudo parted -l |& indent

# Create new partition table?
partitioned=1
if confirm "Create new partition table (ALL DATA WILL BE LOST)?"; then
  ask "Partition which disk?" disk
  while ! ${ssh} sudo parted -s "${disk}" print &>/dev/null; do
    ask "'${disk}' does not exist; partition which disk?" disk
  done

  if really_sure "erase and partition '${disk}'"; then
    partitioned=0
    ensure_unmounted "${boot_device}"
    ensure_unmounted "${root_device}"
    ensure_lv_removed "root"
    ensure_swapoff
    ensure_lv_removed "swap"
    ensure_vg_removed
    ensure_pv_removed
    ensure_luks_closed
    log "Creating partition table"
    parted="${ssh} sudo parted -fs ${disk}"
    ${parted} mklabel gpt |& indent || die "Failed to create partition table"
    log "Creating boot partition (1G)"
    ${parted} mkpart "${boot_name}" fat32 1MiB 1GiB |& indent ||
      die "Failed to create boot partition"
    ${parted} set 1 esp |& indent || die "Failed to mark boot partition as ESP"
    log "Creating LUKS partition with free space"
    ${parted} mkpart "${luks_name}" 1GiB 100% |& indent ||
      die "Failed to create LUKS partition"
  fi
else
  log "Using existing partition table"
fi

# Verify partitions
has_partition "${boot_name}" || die "Missing boot partition '${boot_name}'"
has_partition "${luks_name}" || die "Missing LUKS partition '${luks_name}'"

### BOOT DEVICE ###
if was_partitioned ||
    (! is_boot_fat32 &&
       confirm "Format as FAT32 '${boot_device}'?" &&
       really_sure "format as FAT32 '${boot_device}'")
then
  ensure_unmounted "${boot_device}"
  log "Formatting as FAT32 '${boot_device}'"
  ${ssh} sudo mkfs.fat -F 32 -n BOOT "${boot_device}" |& indent ||
    die "Failed to format as FAT32 '${boot_device}'"
fi

if is_boot_fat32; then
  log "Using boot device '${boot_device}'"
else
  die "Unsuitable boot device '${boot_device}'"
fi

### LUKS DEVICE ###
if was_partitioned ||
    (! is_luks &&
       confirm "Format as LUKS '${luks_device}'?" &&
       really_sure "format as LUKS '${luks_device}'")
then
  ensure_unmounted "${boot_device}"
  ensure_unmounted "${root_device}"
  ensure_lv_removed "root"
  ensure_swapoff
  ensure_lv_removed "swap"
  ensure_vg_removed
  ensure_pv_removed
  ensure_luks_closed
  log "Formatting as LUKS '${luks_device}'"
  (ask_no_echo "Please enter your passphrase:" PASS
   ask_no_echo "Please confirm your passphrase:" CONFIRM
   if [[ "${PASS}" = "${CONFIRM}" ]]; then
     echo "${PASS}" | ${ssh} -t sudo cryptsetup luksFormat "${luks_device}" |&
       indent
     open_luks "${PASS}"
   else
     die "Passphrase does not match"
   fi) || die "Failed to format as LUKS '${luks_device}'"
fi

if is_luks; then
  if ! has_device "${luks_device}" ; then
    ask_no_echo "Please enter your passphrase:" PASS
    open_luks "${PASS}"
  fi
else
  die "Unsuitable LUKS device '${luks_device}'"
fi

### LVM ###
# Check LVM physical volume
if ! has_pv; then
  log "Creating '${lvm_device}' LVM physical volume"
  ${ssh} sudo pvcreate "${lvm_device}" |& indent ||
    die "Failed to create '${lvm_device}' LVM physical volume"
else
  log "Using '${lvm_device}' LVM physical volume"
fi

# Check LVM volume group
if ! has_vg; then
  log "Creating '${vg_name}' LVM volume group"
  (${ssh} sudo vgcreate "${vg_name}" "${lvm_device}" |& indent) ||
    die "Failed to create '${vg_name}' LVM volume group"
else
  log "Using '${vg_name}' LVM volume group"
fi

## SWAP ##
# Create swap LVM volume
if was_partitioned || ! has_lv "swap"; then
  log "Creating 'swap' LVM volume"
  ensure_swapoff
  ensure_lv_removed "swap"
  (if confirm "Should 'swap' be large enough for hibertation?"; then
     swap_factor=3
   else
     swap_factor=2
   fi
   mem_total=$(($(${ssh} grep MemTotal /proc/meminfo | grep -o [[:digit:]]\*) \
                  / 1000000))
   swap_size=$((${mem_total}*${swap_factor}))
   log "Creating '${vg_name}-swap' with ${swap_size}G"
   ${ssh} sudo lvcreate --size "${swap_size}G" --name swap "${vg_name}" |& indent
   wait_for "/dev/mapper/${vg_name}-swap")||
    die "Failed to create 'swap' LVM volume"
fi

# Format swap volume
if was_partitioned ||
    (! is_swap &&
       confirm "Format as swap '${swap_device}'?" &&
       really_sure "format as swap '${swap_device}'")
then
  log "Formatting as swap '${swap_device}'"
  ensure_swapoff
  ${ssh} sudo mkswap -L "swap" "${swap_device}" |& indent ||
    die "Failed to format as swap '${swap_device}'"
fi

if has_lv "swap" &&
    is_swap; then
  if ! is_swapon; then
    log "Enabling swap '${swap_device}'"
    ${ssh} sudo swapon "${swap_device}" |& indent ||
      die "Failed to enable swap '${swap_device}'"
  fi
  log "Using 'swap' LVM volume"
else
  die "Unsuitable swap volume 'swap'"
fi

## ROOT ##
# Check root logical volume filesystem
if was_partitioned || ! has_lv "root"; then
  ensure_unmounted "${root_device}"
  ensure_lv_removed "root"
  log "Creating 'root' LVM volume"
  (${ssh} sudo lvcreate --size -256M --name root ${1} |& indent
   wait_for "/dev/mapper/${vg_name}-root") ||
    die "Failed to create 'root' LVM volume"
fi

# format root
if was_partitioned ||
    (! is_root_ext4 &&
       confirm "Format as ext4 '${root_device}'" &&
       really_sure "format as ext4 '${root_device}'")
then
  log "Using root LVM volume 'root'"
  ensure_unmounted "${root_device}"
  log "Formatting as ext4 '${root_device}'"
  ${ssh} sudo mkfs.ext4 -L "root" "${root_device}" |& indent ||
    die "Failed to format as ext4 '${root_device}'"
fi

if is_root_ext4; then
  log "Using root device '${root_device}'"
  # Mount root
  ensure_mounted "${root_device}" /mnt
else
  die "Unsuitable root device '${root_device}'"
fi

# Mount boot
${ssh} sudo mkdir -p /mnt/boot |& indent
ensure_mounted "${boot_device}" /mnt/boot

## RE-ENCRYPT SECRETS ##
# scp host public key
if [[ ! -e "${scriptdir}/../age/keys/bootstrap.pub" ]]; then
  log "Copying host public key"
  scp "nixos@${ip}:/etc/ssh/ssh_host_ed25519_key.pub" \
      "${scriptdir}/../age/keys/bootstrap.pub"

  # Re-encrypt secrets
  log "Re-encrpting secrets"
  pushd "${scriptdir}/../age"
  ${agenix} -r -i "decrypt-identity.txt" |& indent

  # Commit and push secrets
  # Create temporary branch?
  log "Commit and push secrets"
  git add . |& indent
  git commit -m"Bootstrapping ${hostname}" |& indent
  git push |& indent
  popd
fi

### INSTALL GIT ###
# nixos-install requires git on the PATH
if ${ssh} \[\[ ! -x git  \]\]; then
  log "Installing git"
  ${ssh} sudo nix-env -iA nixos.git
fi

# clone repository
if ! ${ssh} \[\[ -e /mnt/etc/nixos/ \]\]; then
  ${ssh} sudo mkdir -p /mnt/etc |& indent
  log "Cloning repository '${repo}'"
  ${ssh} sudo git clone ${repo} /mnt/etc/nixos/ |& indent
fi

# checkout host branch
ssh_nixos="${ssh} cd /mnt/etc/nixos;"
if [[ $(${ssh_nixos} sudo git branch --show-current 2>/dev/null)\
        != "${hostname}" ]] &&
     ${ssh_nixos} sudo git branch -a | grep "${hostname}" &>/dev/null &&
     confirm "Checkout '${hostname}' branch?"
then
  log "Checking out '${hostname}' branch"
  ${ssh_nixos} sudo git checkout ${hostname} |& indent ||
    die "Failed to checkout '${hostname}' branch"
  ${ssh_nixos} sudo git pull
else
  log "Remaining on current branch"
  ${ssh_nixos} sudo git pull
fi

# copy ssh key for install
if ${ssh} \[\[ ! -f /mnt/tmp/bootstrap.key \]\]; then
  log "Copying ssh host key to '/mnt/tmp/bootstrap.key'"
  ${ssh} sudo mkdir -p /mnt/tmp
  ${ssh} sudo cp /etc/ssh/ssh_host_ed25519_key /mnt/tmp/bootstrap.key
else
  log "Using existing '/mnt/tmp/bootstrap.key'"
fi

## NIXOS INSTALL ##
# Generate NixOS config
log "Generate NixOS config"
${ssh} sudo nixos-generate-config --root /mnt |& indent
log "Copying hardware config to '/mnt/etc/nixos/hosts/${hostname}'"
${ssh} sudo mkdir -p "/mnt/etc/nixos/hosts/${hostname}" |& indent
${ssh} sudo mv /mnt/etc/nixos/hardware-configuration.nix \
       "/mnt/etc/nixos/hosts/${hostname}/" |& indent
${ssh_nixos} sudo git add hosts/${hostname}/hardware-configuration.nix |&
indent

# Install NixOS
log "Ready to install NixOS..."
confirm "Continue?"
log "Installing NixOS"
${ssh_nixos} sudo nixos-install --no-root-password --flake .#${hostname} |& \
  indent ||
  die "Failed to install NixOS"

## COPY LOG ##
log "Copying log file"
log "Installation complete $(date)"
scp "${logfile}" \
    "nixos@${ip}:/tmp/install.log"
${ssh} sudo rm -f "/mnt/etc/nixos/hosts/${hostname}/install.log"
${ssh} sudo mv /tmp/install.log "/mnt/etc/nixos/hosts/${hostname}"
