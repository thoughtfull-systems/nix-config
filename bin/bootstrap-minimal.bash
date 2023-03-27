#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Save reference to stdout and stderr
exec 3>&1 4>&2
# Restore stdout and stderr on signal
trap 'exec 2>&4 1>&3' 0 1 2 3
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

# Validate ip argument
([[ -v 2 ]] && (ping -c1 "${2}" &>/dev/null)) ||
  die "Expected IP address as second argument"
ip="${2}"

### VARIABLES ##################################################################
# programs
ssh="ssh nixos@${ip} -qt"
file="${nix} run nixpkgs#file -- -sL"

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
  echo "??? Are your REALLY sure you want to ${1}?"
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
  ${ssh} mount \| grep "\$(realpath ${1})" &>/dev/null
}

function ensure_unmounted {
  if is_mounted "${1}"; then
    log "Unmounting '${1}'"
    ${ssh} sudo umount "\$(realpath ${1})" |& indent
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
  echo "${3}" | ${ssh} sudo cryptsetup open "${1}" "${2}" |& indent ||
    die "Failed to open '${luks_device}'"
  wait_for "/dev/mapper/${2}"
}

function format_luks {
  ask_no_echo "Please enter your passphrase:" PASS
  ask_no_echo "Please confirm your passphrase:" CONFIRM
  if [[ "${PASS}" = "${CONFIRM}" ]]; then
    echo "${PASS}" | ${ssh} sudo cryptsetup luksFormat "${1}" |& indent
    log "Using LUKS device '${1}'"
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
  ${ssh} sudo mkfs.fat -F 32 "${1}" -n BOOT |& indent;
}

# Swap
function has_swap {
  (${ssh} sudo lvs -S "vg_name=${1} && lv_name=swap" |
     grep swap) &>/dev/null
}

function mkswap {
  if confirm "Should 'swap' be large enough for hibertation?"; then
    swap_factor=3
  else
    swap_factor=2
  fi
  mem_total=$(($(${ssh} grep MemTotal /proc/meminfo | grep -o [[:digit:]]\*) / 1000000))
  swap_size=$((${mem_total}*${swap_factor}))
  log "Creating '${1}-swap' with ${swap_size}G"
  ${ssh} sudo lvcreate --size ${swap_size}G --name swap ${1} |& indent
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

### SETUP ######################################################################
# Confirm ssh access to machine
if ${ssh} : &>/dev/null; then
  log "Confirmed SSH access to machine"
else
  die "Set up SSH access to '${ip}' (either password or public key)"
fi

### PARTITION TABLE ###
${ssh} sudo parted -l |& indent

# Create new partition table?
if confirm "Create new partition table (ALL DATA WILL BE LOST)?"; then
  ask "Partition which disk?" disk
  while ! ${ssh} sudo parted -s "${disk}" print &>/dev/null; do
    ask "'${disk}' does not exist; partition which disk?" disk
  done

  if really_sure "erase and partition '${disk}'"; then
    ensure_unmounted "${boot_device}"
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
    ${parted} mkpart ${boot_name} fat32 1MiB 1GiB |& indent ||
      die "Failed to create boot partition"
    ${parted} set 1 esp |& indent || die "Failed to mark boot partition as ESP"
    log "Creating LUKS partition with free space"
    ${parted} mkpart ${luks_name} 1GiB 100% |& indent ||
      die "Failed to create LUKS partition"
  fi
fi

# Verify partitions
has_partition "${boot_name}" || die "Missing boot partition '${boot_name}'"
has_partition "${luks_name}" || die "Missing LUKS partition '${luks_name}'"

### BOOT DEVICE ###
if ! is_fat32 "${boot_device}"; then
  (confirm "Format as FAT32 '${boot_device}'?"
   ensure_unmounted "${boot_device}"
   log "Formatting as FAT32 '${boot_device}'"
   mkfat32 "${boot_device}") ||
    die "Failed to format as FAT32 '${boot_device}'"
else
  if confirm "Re-format as FAT32 '${boot_device}'?"; then
    really_sure "re-format as FAT 32 '${boot_device}' (ALL DATA WILL BE LOST)"
    (ensure_unmounted "${boot_device}"
     log "Re-formatting as FAT32 '${boot_device}'"
     mkfat32 "${boot_device}") ||
      die "Failed to re-format as FAT32 '${boot_device}'"
  fi
fi

if is_fat32 "${boot_device}"; then
  log "Using boot device '${boot_device}'"
else
  die "Unsuitable boot device '${boot_device}'"
fi

### LUKS DEVICE ###
if ! is_luks "${luks_device}"; then
  if confirm "Format as LUKS '${luks_device}'?"; then
    log "Formatting as LUKS '${luks_device}'"
    format_luks "${luks_device}" "${lvm_name}" ||
      die "Failed to format as LUKS '${luks_device}'"
  fi
else
  if confirm "Re-format as LUKS '${luks_device}'?"; then
    really_sure "re-format as LUKS '${luks_device}' (ALL DATA WILL BE LOST)"
    log "Re-formatting as LUKS '${luks_device}'"
    (ensure_unmounted "${boot_device}"
     ensure_unmounted "${root_device}"
     ensure_swapoff "${swap_device}"
     ensure_lv_removed "${vg_name}" "swap"
     ensure_lv_removed "${vg_name}" "root"
     ensure_vg_removed "${vg_name}"
     ensure_pv_removed "${luks_device}"
     ensure_luks_closed "${lvm_device}"
     format_luks "${luks_device}" "${lvm_name}") ||
      die "Failed to re-format as LUKS '${luks_device}'"
  fi
fi

if ! has_device "${lvm_device}"; then
  log "Using LUKS device '${1}'"
  ask_no_echo "Please enter your passphrase:" PASS
  open_luks "${luks_device}" "${lvm_name}" "${PASS}"
fi

### LVM ###
# Check LVM physical volume
if ! (${ssh} sudo pvs | grep "${lvm_device}") &>/dev/null; then
  log "Creating '${lvm_device}' LVM physical volume"
  ${ssh} sudo pvcreate "${lvm_device}" |& indent ||
    die "Failed to create '${lvm_device}' LVM physical volume"
else
  log "Using '${lvm_device}' LVM physical volume"
fi

# Check LVM volume group
if ! (${ssh} sudo vgs | grep "${vg_name}") &>/dev/null; then
  log "Creating '${vg_name}' LVM volume group"
  (${ssh} sudo vgcreate "${vg_name}" "${lvm_device}" |& indent) ||
    die "Failed to create '${vg_name}' LVM volume group"
else
  log "Using '${vg_name}' LVM volume group"
fi

## SWAP ##
# Create swap LVM volume
if ! has_swap "${vg_name}"; then
  log "Creating 'swap' LVM volume"
  mkswap "${vg_name}"
else
  if confirm "Re-create 'swap' LVM volume"; then
    log "Re-creating 'swap' LVM volume"
    (ensure_swapoff "${swap_device}"
     ${ssh} sudo lvremove "${vg_name}/swap"
     ${ssh} mkswap "${vg-name}") ||
      die "Failed to re-create 'swap' LVM volume"
  fi
fi
log "Using 'swap' LVM volume"

# Format swap volume
if ! is_swap "${swap_device}"; then
  if confirm "Format as swap '${swap_device}'?"; then
    ${ssh} sudo mkswap -L swap "${swap_device}" |& indent
  fi
fi

if ! is_swapon "${swap_device}"; then
  log "Enabling swap '${swap_device}'"
  ${ssh} sudo swapon "${swap_device}" |& indent
fi

## ROOT ##
# Check root logical volume filesystem
if ! has_lv "${vg_name}" "${root_name}"; then
  log "Creating '${root_name}' LVM volume"
  (${ssh} sudo lvcreate --extents 100%FREE --name root ${1} |& indent
   wait_for "${root_device}") || die "Failed to format '${root_device}'"
else
  log "Using '${root_device}' root partition"
  if confirm "Re-create '${root_name}' LVM volume"; then
    really_sure "erase all data on '${root_device}' and re-format it"
    log "Re-creating '${root_name}' LVM volume"
    ${ssh} sudo lvremove "${vg_name}/${root_name}" |& indent
    log "Creating '${root_name}' LVM volume"
    (${ssh} sudo lvcreate --extents 100%FREE --name root ${1} |& indent
     wait_for "/dev/mapper/${1}-root") ||
      die "Failed to re-format '${root_name}'"
  fi
fi

# Mount root filesystem

# Mount boot filesystem

# Turn on swap

# scp host public key

# Re-encrypt secrets

# Create temporary branch?

# Commit and push secrets

# Generate NixOS config

# Install NixOS

# - (confirm) format unformatted boot partition, or re-format formatted boot
# partition?

#   - format boot parition as FAT32

# - (confirm) luksFormat unformatted luks partition, or re-luksFormat formatted
# luks partition?

# heading "BEGIN bootstrapping $(date)"

# ## Download SSH host public key
# tempdir=$(mktemp -d)
# tempfile="${tempdir}/ssh_host_ed25519_key.pub"
# bootstrapfile="${scriptdir}/../age/keys/bootstrap.pub"
# log "Copying bootstrap key to ${tempfile}"
# scp "${scpargs[@]}" "nixos@${ip}:/etc/ssh/ssh_host_ed25519_key.pub" "${tempdir}"
# if [[ $(cat "${tempfile}") != $(cat "${bootstrapfile}") ]]; then
#   log "Replacing ${bootstrapfile} with ${tempfile}"
#   mv "${tempfile}" "${bootstrapfile}"

#   ## Re-key secrets
#   pushd "${scriptdir}/../age"
#   nix run "${agenix}" -- -r -i "decrypt-identity.txt"
#   popd

#   ## Commit and push new secrets
#   git add "${scriptdir}/../age"
#   git commit -m"Bootstrapping ${hostname}"
#   git push
# else
#   log "Using ${bootstrapfile} as is"
#   rm "${tempfile}"
# fi

# ## SCP bootstrap script
# scp "${scpargs[@]}" "${scriptdir}/${configscript}" "nixos@${ip}:${configscript}"

# heading "END bootstrapping $(date)"

# ## SSH and execute bootstrap script
# ssh "${scpargs[@]}" -t "nixos@${ip}" sudo bash "${configscript}" "${hostname}"
