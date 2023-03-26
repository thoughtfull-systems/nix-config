#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "### Temporary log file '${logfile}'"
# Save reference to stdout and stderr
exec 3>&1 4>&2
# Restore stdout and stderr on signal
trap 'exec 2>&4 1>&3' 0 1 2 3
# Redirect tee stdout and stderr to logfile
exec 1> >(tee ${logfile}) 2>&1

### EVERYTHING BELOW WILL GO TO CONSOLE AND LOGFILE ###
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

## STAGE 1 ##
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
  (${git} pull |& indent) ||
    die "Failed fetch latest from origin"
  log "Working directory up-to-date"
}
if (${git} branch -a | grep "${hostname}") &>/dev/null &&
     [[ ! $(${git} branch --show-current 2>/dev/null) = "${hostname}" ]] &&
     confirm "Checkout '${hostname}' branch?"
then
  log "Checking out '${hostname}' branch"
  (${git} checkout ${hostname} |& indent) ||
    die "Failed to checkout '${hostname}' branch"
  pull_latest
  log "Exec'ing new script"
  exec $(realpath ${0}) "${@}" ||
    die "Failed to exec new script"
else
  log "Remaining on current branch"
  pull_latest
fi
### SCRIPT IS RELOADED ###

# Validate ip argument
([[ -v 2 ]] && (ping -c1 "${2}" &>/dev/null)) ||
  die "Expected IP address as second argument"
ip="${2}"

# Confirm ssh access to machine
ssh="ssh nixos@${ip} -qt"

if ${ssh} : &>/dev/null; then
  log "Confirmed SSH access to machine"
else
  die "Set up SSH access to '${ip}' (either password or public key)"
fi

# Check for partitions
function has_device {
  ${ssh} "[[ -b \"${1}\" ]]" &>/dev/null
}
function has_partition {
  has_device "/dev/disk/by-partlabel/${1}"
}
boot_name="${hostname}-boot"
has_partition "${boot_name}" || log "Missing '${boot_name}' partition"
crypt_name="${hostname}-lvm-crypt"
has_partition "${crypt_name}" || log "Missing '${crypt_name}' partition"

${ssh} sudo parted -l |& indent

function really_sure {
  echo "??? Are your REALLY sure you want to ${1}?"
  ask "(Please enter YES in all caps):"

  if [[ $REPLY = "YES" ]]; then
    return 0;
  else
    return 1;
  fi
}

# Create new partition table?
if confirm "Create new partition table (ALL DATA WILL BE LOST)?"; then
  ask "Partition which disk?" disk
  while ! ${ssh} sudo parted -s "${disk}" print &>/dev/null; do
    ask "'${disk}' does not exist; partition which disk?" disk
  done

  if really_sure "erase and partition '${disk}'"; then
    log "Creating partition table"
    parted="${ssh} sudo parted -fs ${disk}"
    (${parted} mklabel gpt |& indent) ||
      die "Failed to create partition table"
    log "Creating boot partition (1G)"
    (${parted} mkpart ${boot_name} fat32 1MiB 1GiB |&
     indent) ||
      die "Failed to create boot partition"
    (${parted} set 1 esp |& indent) ||
      die "Failed to mark boot partition as ESP"
    log "Creating LUKS partition with free space"
    (${parted} mkpart ${crypt_name} 1GiB 100% |& indent) ||
      die "Failed to create LUKS partition"
  fi
fi

# Verify partitions
if has_partition "${boot_name}"; then
  log "Using '${boot_name}' partition"
else
  die "Missing '${boot_name}' partition"
fi
boot_device="/dev/disk/by-partlabel/${boot_name}"

if has_partition "${crypt_name}"; then
  log "Using '${crypt_name}' partition"
else
  die "Missing '${crypt_name}' partition"
fi
crypt_device="/dev/disk/by-partlabel/${crypt_name}"

# Check boot filesystem
file="${nix} run nixpkgs#file -- -sL"
function is_fat32 {
  (${ssh} sudo ${file} "${1}" | grep "FAT (32 bit)") &>/dev/null
}
function mkfat32 { ${ssh} sudo mkfs.fat -F 32 "${1}" -n BOOT |& indent; }
if ! is_fat32 "${boot_device}"; then
  if confirm "Format '${boot_device}' as FAT32 filesystem?"; then
    log "Formatting '${boot_device}' as FAT32 filesystem"
    mkfat32 "${boot_device}" ||
      die "Failed to format '${boot_device}'"
  fi
else
  if confirm "Re-format '${boot_device}' as FAT32 filesystem?"; then
    really_sure "erase all data on '${boot_device}' and re-format it"
    log "Re-formatting '${boot_device}' as FAT32 filesystem"
    mkfat32 "${boot_device}" ||
      die "Failed to format '${boot_device}'"
  fi
fi

# Check luks partition
function is_luks { ${ssh} sudo cryptsetup isLuks "${1}"; }
function wait_for() {
  if ${ssh} "[[ ! -e \"${1}\" ]]"; then
    log "Waiting for '${1}'..."
    while ${ssh} "[[ ! -e \"${1}\" ]]"; do
      sleep 1
    done
  fi
}
function is_swapon { ${ssh} sudo swapon | grep "$(realpath ${1})" &>/dev/null; }
function ensure_swapoff {
  is_swapon "${1}"
  ${ssh} sudo swapoff "$(realpath ${1})" &>/dev/null
}
function mkluks {
  # TODO unmount
  ensure_swapoff
  # TODO remove LVM
  # TODO close LUKS
  ask_no_echo "Please enter your passphrase:" PASS
  ask_no_echo "Please confirm your passphrase:" CONFIRM
  if [[ "${PASS}" = "${CONFIRM}" ]]; then
    (echo "${PASS}" | ${ssh} sudo cryptsetup luksFormat "${1}" |& indent)
    (echo "${PASS}" | ${ssh} sudo cryptsetup open "${1}" "${2}" |& indent)
    wait_for "/dev/mapper/${2}"
  else
    die "Passphrase does not match"
  fi
}
function ask_no_echo() {
  msg="??? ${1} "
  read -sp "${msg}" ${2}
  # prevents bunching in the log (because input is not logged)
  echo
}
lvm_name="${hostname}-lvm"
if ! is_luks "${crypt_device}"; then
  if confirm "Format '${crypt_device}' as LUKS container?"; then
    log "Formatting '${crypt_device}' as LUKS container"
    mkluks "${crypt_device}" "${lvm_name}" ||
      die "Failed to format '${crypt_device}'"
  fi
else
  if confirm "Re-format '${crypt_device}' as LUKS container?"; then
    really_sure "erase all data on '${crypt_device}' and re-format it"
    log "Re-formatting '${crypt_device}' as LUKS container"
    mkluks "${crypt_device}" "${lvm_name}" ||
      die "Failed to re-format '${crypt_device}'"
  fi
fi

if ! has_device "/dev/mapper/${lvm_name}"; then
  (ask_no_echo "Please enter your passphrase:" PASS
   (echo "${PASS}" |
      ${ssh} sudo cryptsetup open "${crypt_device}" "${lvm_name}" |&
      indent)
   wait_for "/dev/mapper/${lvm_name}") ||
    die "Failed to open '${crypt_device}'"
fi

# Check LVM physical volume
lvm_device="/dev/mapper/${lvm_name}"
if ! (${ssh} sudo pvs | grep "${lvm_device}") &>/dev/null; then
  log "Creating '${lvm_device}' LVM physical volume"
  (${ssh} sudo pvcreate "${lvm_device}" |& indent) ||
    die "Failed to create '${lvm_device}' LVM physical volume"
else
  log "Using '${lvm_device}' LVM physical volume"
fi

# Check LVM volume group
vg_name="${hostname}"
if ! (${ssh} sudo vgs | grep "${vg_name}") &>/dev/null; then
  log "Creating '${vg_name}' LVM volume group"
  (${ssh} sudo vgcreate "${vg_name}" "${lvm_device}" |& indent) ||
    die "Failed to create '${vg_name}' LVM volume group"
else
  log "Using '${vg_name}' LVM volume group"
fi

# Check swap logical volume filesystem
swap_device="/dev/mapper/${vg_name}-swap"
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
if ! has_swap "${vg_name}"; then
  log "Creating 'swap' LVM volume"
  mkswap "${vg_name}"
else
  confirm "Re-create 'swap' LVM volume"
  log "Re-creating 'swap' LVM volume"
  (ensure_swapoff "${swap_device}" &&
     ${ssh} sudo lvremove "${vg_name}/swap" &&
     ${ssh} mkswap "${vg-name}") ||
    die "Failed to re-create 'swap' LVM volume"
fi
log "Using 'swap' LVM volume"

if ! is_swapon "${swap_device}"; then
  log "Enabling swap '${swap_device}'"
  ${ssh} sudo swapon ${swap_device}
fi

# Check root logical volume filesystem
root_device="/dev/mapper/${hostname}-root"
function mkroot {
  log "Creating '${1}-root'"
  ${ssh} sudo lvcreate --extends 100%FREE --name root ${1} |& indent
  wait_for "/dev/mapper/${1}-root"
}
if ! has_partition ${root_name}; then
  log "Creating 'root' LVM volume"
  mkroot "${vg_name}"
else
  log "Using '${root_device}' root partition"
  if confirm "Re-create 'root' LVM volume"; then
    really_sure "erase all data on '${root_device}' and re-format it"
    log "Re-creating '${root_device}' LVM volume"
    ${ssh} sudo lvremove ${vg_name}/root |& indent
    mkroot "${vg_name}" ||
      die "Failed to re-format '${crypt_device}'"
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
