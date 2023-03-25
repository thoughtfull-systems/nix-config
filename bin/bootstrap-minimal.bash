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
git="nix run nixpkgs#git --"

# Verify git working dir is clean
if (output=$(${git} status --porcelain 2>/dev/null) &&
      [[ -z "${output}" ]])
then
  log "Working directory is clean"
else
  die "Working directory is dirty"
fi

# Validate hostname argument
[[ -v 1 ]] || die "Expected hostname as first argument"
hostname="${1}"

function indent { sed -E 's/\r$//g;s/\r/\n/g' | sed -E "s/^/    /g"; }

# Checkout hostname branch?
if (${git} branch -a | grep "${hostname}") &>/dev/null &&
     [[ ! $(${git} branch --show-current 2>/dev/null) = "${hostname}" ]] &&
     confirm "Checkout '${hostname}' branch?"
then
  log "Checking out '${hostname}' branch"
  ${git} checkout ${hostname} |& indent
  log "Fetching latest from origin"
  ${git} pull |& indent
  log "Working directory up-to-date"
  log "Exec'ing into new script"
  exec $(realpath ${0}) "${@}"
else
  log "Fetching latest from origin"
  ${git} pull |& indent
  log "Working directory up-to-date"
fi

### SCRIPT IS RELOADED ###
## STAGE 2 ##
# Validate ip argument
([[ -v 2 ]] && (ping -c1 "${2}" &>/dev/null)) ||
  die "Expected IP address as second argument"
ip="${2}"

# Confirm ssh access to machine
ssh="ssh nixos@${ip} -qt"
if ${ssh} : &>/dev/null; then
  log "Confirmed SSH access to machine"
else
  # Manually enable ssh access with password or ssh key
  die "Set up SSH access to '${ip}' (either password or public key)"
fi

# Check for partitions
function has_partition {
  ${ssh} "[[ -b \"/dev/disk/by-partlabel/${1}\" ]]" &>/dev/null
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
    ${ssh} sudo parted -fs ${disk} mklabel gpt |& indent
    log "Creating boot partition (1G)"
    ${ssh} sudo parted -fs ${disk} mkpart ${boot_name} fat32 1MiB 1GiB 2>&1 |
      indent
    ${ssh} sudo parted -fs ${disk} set 1 esp |& indent
    log "Creating luks partition with free space"
    ${ssh} sudo parted -fs ${disk} mkpart ${crypt_name} 1GiB 100% |& indent
  fi
fi

# Verify partitions
boot_device="/dev/disk/by-partlabel/${boot_name}"
if has_partition "${boot_name}"; then
  log "Using '${boot_device}' partition"
else
  die "Missing '${boot_name}' partition"
fi
crypt_device="/dev/disk/by-partlabel/${crypt_name}"
if has_partition "${crypt_name}"; then
  log "Using '${crypt_device}' partition"
else
  die "Missing '${crypt_name}' partition"
fi

# Check boot filesystem
file="nix --extra-experimental-features nix-command \
          --extra-experimental-features flakes \
          run nixpkgs#file -- -sL"
function is_fat32 {
  (${ssh} sudo ${file} "${1}" | grep "FAT (32 bit)") &>/dev/null
}
function mkfat32 { ${ssh} sudo mkfs.fat -F 32 "${1}" -n BOOT |& indent; }
if ! is_fat32 "${boot_device}" &&
    confirm "Format '${boot_device}' as FAT32 filesystem?"
then
  log "Formatting '${boot_device}' as FAT32 filesystem"
  mkfat32 "${boot_device}" ||
    die "Failed to format '${boot_device}'"
elif is_fat32 "${boot_device}" && confirm "Re-format '${boot_device}'?"; then
  really_sure "erase all data on '${boot_device}' and re-format it" &&
    mkfat32 "${boot_device}" ||
      die "Failed to format '${boot_device}'"
fi

# Check luks partition
function is_luks { ${ssh} sudo cryptsetup isLuks "${1}"; }
function mkluks {
  # TODO unmount
  # TODO remove LVM
  # TODO close LUKS
  ask_no_echo "Please enter your passphrase:" PASS &&
    ask_no_echo "Please confirm your passphrase:" CONFIRM
  if [[ "${PASS}" = "${CONFIRM}" ]]; then
    (echo "${PASS}" | ${ssh} sudo cryptsetup luksFormat "${1}" |& indent) &&
      (echo "${PASS}" | ${ssh} sudo cryptsetup open "${1}" "${2}" |& indent)
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
if ! is_luks "${crypt_device}" &&
    confirm "Format '${crypt_device}' as LUKS container?"
then
  log "Formatting '${crypt_device}' as LUKS container"
  if really_sure "erase all data on '${crypt_device}' and re-format it"; then
    mkluks "${crypt_device}" "${lvm_name}" ||
      die "Failed to re-format '${crypt_device}'"
  fi
elif is_luks "${crypt_device}" &&
    confirm "Re-format '${crypt_device}'"
then
  if really_sure "erase all data on '${crypt_device}' and re-format it"; then
    mkluks "${crypt_device}" "${lvm_name}" ||
      die "Failed to re-format '${crypt_device}'"
  fi
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
if ! (${ssh} sudo vgs | grep "${lvm_device}") &>/dev/null; then
  log "Creating '${hostname}' LVM volume group"
  (${ssh} sudo vgcreate "${hostname}" "${lvm_device}" |& indent) ||
    die "Failed to create '${hostname}' LVM volume group"
else
  log "Using '${hostname}' LVM volume group"
fi

# Check LVM logical volumes

# Check swap logical volume filesystem

# Check root logical volume filesystem

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
