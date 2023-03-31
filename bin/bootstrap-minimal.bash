#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Save reference to stdout and stderr
exec 3>&1 4>&2
# Restore stdout and stderr on signal
# trap 'exec 2>&4 1>&3' 0 1 2 3
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ############################
set -euo pipefail

function die { echo "!!! ${1}" >&2; exit 1; }
function log { echo "=== ${1}"; }

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
  if [[ ${REPLY} =~ ^[Yy].* ]]; then
    return 0
  else
    return 1
  fi
}

function is_git_clean {
  output=$(${git} status --porcelain 2>/dev/null) && [[ -z "${output}" ]]
}


nix="nix --extra-experimental-features nix-command \
         --extra-experimental-features flakes"
git="${nix} run nixpkgs#git --"

# Verify git working dir is clean
if is_git_clean; then
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
    die "Failed fetch latest from origin"
  log "Working directory up-to-date"
}
if (${git} branch -a | grep "${hostname}") &>/dev/null &&
     [[ ! $(${git} branch --show-current 2>/dev/null) = "${hostname}" ]] &&
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
ssh="ssh nixos@${ip} -qt"
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
swap_name="swap"
swap_device="/dev/mapper/${vg_name}-${swap_name}"
root_name="root"
root_device="/dev/mapper/${hostname}-${root_name}"

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

  # TODO: do I need the if???
  if [[ $REPLY = "YES" ]]; then
    return 0;
  else
    return 1;
  fi
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
}

# LUKS
function is_luks { ${ssh} sudo cryptsetup isLuks "${1}"; }

function wait_for() {
  if ${ssh} "[[ ! -e \"${1}\" ]]" &>/dev/null; then
    log "Waiting for '${1}'..."
    while ${ssh} "[[ ! -e \"${1}\" ]]" &>/dev/null; do
      sleep 1
    done
  fi
}

function ensure_luks_closed {
  if has_device "${1}"; then
    log "Closing LUKS device '${1}'"
    ${ssh} sudo cryptsetup close "${1}"
  fi
}

function open_luks {
  log "Using LUKS device '${1}'"
  echo "${3}" | ${ssh} sudo cryptsetup open "${1}" "${2}" |& indent ||
    die "Failed to open '${luks_device}'"
  wait_for "/dev/mapper/${2}"
}

function format_luks {
  ask_no_echo "Please enter your passphrase:" PASS
  ask_no_echo "Please confirm your passphrase:" CONFIRM
  if [[ "${PASS}" = "${CONFIRM}" ]]; then
    echo "${PASS}" | ${ssh} sudo cryptsetup luksFormat "${1}" |& indent
    open_luks "${1}" "${2}" "${PASS}"
  else
    die "Passphrase does not match"
  fi
}

# LVM
function has_pv {
  ${ssh} sudo pvs | grep "${1}" &>/dev/null
}

function ensure_pv_removed {
  if has_pv "${1}"; then
    log "Removing physical volume '${1}'"
    ${ssh} sudo pvremove -y "${1}" |& indent
  fi
}

function has_vg {
  ${ssh} sudo vgs | grep "${1}" &>/dev/null
}

function ensure_vg_removed {
  if has_vg "${1}"; then
    log "Removing volume group '${1}'"
    ${ssh} sudo vgremove -y "${1}"
  fi
}

function has_lv {
  ${ssh} sudo lvs -S "vg_name=${1} && lv_name=${2}" | grep "${2}" &>/dev/null
}

function ensure_lv_removed {
  if has_lv "${1}" "${2}"; then
    log "Removing volume '${2}'"
    ${ssh} sudo lvremove -y "${1}/${2}" |& indent
  fi
}

# FAT32
function is_fat32 {
  (${ssh} sudo ${file} "${1}" | grep "FAT (32 bit)") &>/dev/null
}

function mkfat32 {
  ensure_unmounted "${1}"
}

# Swap
function mkswap {
  if confirm "Should 'swap' be large enough for hibertation?"; then
    swap_factor=3
  else
    swap_factor=2
  fi
  mem_total=$(($(${ssh} grep MemTotal /proc/meminfo | grep -o [[:digit:]]\*) \
                 / 1000000))
  swap_size=$((${mem_total}*${swap_factor}))
  log "Creating '${1}-swap' with ${swap_size}G"
  ${ssh} sudo lvcreate --size "${swap_size}G" --name swap "${1}" |& indent
  wait_for "/dev/mapper/${1}-swap"
}

function is_swap {
  ${ssh} sudo swaplabel "${1}" &>/dev/null
}

function is_swapon {
  ${ssh} sudo swapon \| grep "\$(realpath ${1})" &>/dev/null
}

function ensure_swapoff {
  if is_swapon "${1}"; then
    ${ssh} sudo swapoff "\$(realpath ${1})" |& indent ||
      die "Failed to disable swap '${1}'"
  fi
}

function is_ext4() {
  ${ssh} sudo ${file} -sL "${1}" | grep "ext4 filesystem" &>/dev/null
}

function was_partitioned {
  [[ ${partitioned} -eq 0 ]]
}

### SETUP ######################################################################
# Confirm ssh access to machine
if ${ssh} : 1>/dev/null; then
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
    # TODO: make specific functions?
    ensure_unmounted "\$(realpath ${boot_device})"
    ensure_unmounted "${root_device}"
    ensure_lv_removed "${vg_name}" "${root_name}"
    ensure_swapoff "${swap_device}"
    ensure_lv_removed "${vg_name}" "${swap_name}"
    ensure_vg_removed "${vg_name}"
    ensure_pv_removed "${luks_device}"
    ensure_luks_closed "${lvm_device}"
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
fi

# Verify partitions
has_partition "${boot_name}" || die "Missing boot partition '${boot_name}'"
has_partition "${luks_name}" || die "Missing LUKS partition '${luks_name}'"

### BOOT DEVICE ###
if was_partitioned ||
    (! is_fat32 "${boot_device}" &&
       confirm "Format as FAT32 '${boot_device}'?" &&
       really_sure "format as FAT32 '${boot_device}'")
then
  ensure_unmounted "${boot_device}"
  log "Formatting as FAT32 '${boot_device}'"
  ${ssh} sudo mkfs.fat -F 32 -n BOOT "${boot_device}" |& indent ||
    die "Failed to format as FAT32 '${boot_device}'"
fi

if is_fat32 "${boot_device}"; then
  log "Using boot device '${boot_device}'"
else
  die "Unsuitable boot device '${boot_device}'"
fi

### LUKS DEVICE ###
if was_partitioned ||
    (! is_luks "${luks_device}" &&
       confirm "Format as LUKS '${luks_device}'?" &&
       really_sure "format as LUKS '${luks_device}'")
then
  ensure_unmounted "${boot_device}"
  ensure_unmounted "${root_device}"
  ensure_lv_removed "${vg_name}" "${root_name}"
  ensure_swapoff "${swap_device}"
  ensure_lv_removed "${vg_name}" "${swap_name}"
  ensure_vg_removed "${vg_name}"
  ensure_pv_removed "${luks_device}"
  ensure_luks_closed "${lvm_device}"
  log "Formatting as LUKS '${luks_device}'"
  format_luks "${luks_device}" "${lvm_name}" ||
    die "Failed to format as LUKS '${luks_device}'"
fi

if is_luks "${luks_device}"; then
  if ! has_device "${luks_device}" ; then
    ask_no_echo "Please enter your passphrase:" PASS
    open_luks "${luks_device}" "${lvm_name}" "${PASS}"
  fi
else
  die "Unsuitable LUKS device '${luks_device}'"
fi

### LVM ###
# Check LVM physical volume
if ! has_pv "${lvm_device}"; then
  log "Creating '${lvm_device}' LVM physical volume"
  ${ssh} sudo pvcreate "${lvm_device}" |& indent ||
    die "Failed to create '${lvm_device}' LVM physical volume"
else
  log "Using '${lvm_device}' LVM physical volume"
fi

# Check LVM volume group
if ! has_vg "${vg_name}"; then
  log "Creating '${vg_name}' LVM volume group"
  (${ssh} sudo vgcreate "${vg_name}" "${lvm_device}" |& indent) ||
    die "Failed to create '${vg_name}' LVM volume group"
else
  log "Using '${vg_name}' LVM volume group"
fi

## SWAP ##
# Create swap LVM volume
if was_partitioned || ! has_lv "${vg_name}" "${swap_name}"; then
  log "Creating '${swap_name}' LVM volume"
  ensure_swapoff "${swap_device}"
  ensure_lv_removed "${vg_name}" "${swap_name}"
  mkswap "${vg_name}" "${swap_name}" ||
    die "Failed to create '${swap_name}' LVM volume"
fi

# Format swap volume
if was_partitioned ||
    (! is_swap "${swap_device}" &&
       confirm "Format as swap '${swap_device}'?" &&
       really_sure "format as swap '${swap_device}'")
then
  log "Formatting as swap '${swap_device}'"
  ensure_swapoff "${swap_device}"
  ${ssh} sudo mkswap -L "${swap_name}" "${swap_device}" |& indent ||
    die "Failed to format as swap '${swap_device}'"
fi

if has_lv "${vg_name}" "${swap_name}" &&
    is_swap "${swap_device}"; then
  log "Using '${swap_name}' LVM volume"
  if ! is_swapon "${swap_device}"; then
    log "Enabling swap '${swap_device}'"
    ${ssh} sudo swapon "${swap_device}" |& indent ||
      die "Failed to enable swap '${swap_device}'"
  fi
else
  die "Unsuitable swap volume ${swap_name}"
fi

## ROOT ##
# Check root logical volume filesystem
if was_partitioned || ! has_lv "${vg_name}" "${root_name}"; then
  ensure_unmounted "${root_device}"
  ensure_lv_removed "${vg_name}" "${root_name}"
  log "Creating '${root_name}' LVM volume"
  (${ssh} sudo lvcreate --extents 100%FREE --name root ${1} |& indent
   wait_for "/dev/mapper/${vg_name}-root") ||
    die "Failed to create '${root_name}' LVM volume"
fi

# format root
if was_partitioned ||
    (! is_ext4 "${root_device}" &&
       confirm "Format as ext4 '${root_device}'" &&
       really_sure "format as ext4 '${root_device}'")
then
  log "Using root LVM volume '${root_name}'"
  ensure_unmounted "${root_device}"
  log "Formatting as ext4 '${root_device}'"
  ${ssh} sudo mkfs.ext4 -L "${root_name}" "${root_device}" |& indent ||
    die "Failed to format as ext4 '${root_device}'"
fi

if is_ext4 "${root_device}"; then
  log "Using root device '${boot_device}'"
  # Mount root
  if ! is_mounted "${root_device}"; then
    log "Mounting '${root_device}'"
    ${ssh} sudo mount "${root_device}" /mnt |& indent ||
      die "Failed to mount '${root_device}'"
  fi
else
  die "Unsuitable root device '${root_device}'"
fi

# Mount boot
if ! is_mounted "\$(realpath ${boot_device})"; then
  log "Mounting '${boot_device}'"
  (${ssh} sudo mkdir -p /mnt/boot |& indent
   ${ssh} sudo mount "${boot_device}" /mnt/boot |& indent) ||
    die "Failed to mount '${boot_device}'"
fi

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
if (${ssh_nixos} sudo git branch -a | grep "${hostname}") &>/dev/null &&
     [[ ! $(${ssh_nixos} sudo git branch --show-current 2>/dev/null) = \
          "${hostname}" ]] &&
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
log "Copy hardware config"
${ssh} sudo mkdir -p "/mnt/etc/nixos/hosts/${hostname}" |& indent
${ssh} sudo mv /mnt/etc/nixos/hardware-configuration.nix \
       "/mnt/etc/nixos/hosts/${hostname}/" |& indent
${ssh_nixos} sudo git add hosts/${hostname}/hardware-configuration.nix |&
indent

# Install NixOS
log "Installing NixOS..."
confirm "Continue?"
${ssh_nixos} sudo nixos-install --no-root-password --flake .#${hostname} |& \
  indent ||
  die "Failed to install NixOS"

## COPY LOG ##
# TODO: copy log
