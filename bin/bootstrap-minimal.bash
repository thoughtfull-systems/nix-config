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
if (output=$(${git} status --porcelain 2>/dev/null) && \
      [[ -z "${output}" ]]); then
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
     [[ ! $(${git} branch --show-current 2>/dev/null) = "${hostname}" ]] && \
       confirm "Checkout '${hostname}' branch?"; then
  log "Checking out '${hostname}' branch"
  ${git} checkout ${hostname} 2>&1 | indent
  log "Fetching latest from origin"
  ${git} pull 2>&1 | indent
  log "Working directory up-to-date"
  log "Exec'ing into new script"
  exec $(realpath ${0}) "${@}"
else
  log "Fetching latest from origin"
  ${git} pull 2>&1 | indent
  log "Working directory up-to-date"
fi

### SCRIPT IS RELOADED ###
## STAGE 2 ##
# Validate ip argument
([[ -v 2 ]] && (ping -c1 "${2}" &>/dev/null)) || \
  die "Expected IP address as second argument"
ip="${2}"

ssh="ssh nixos@${ip} -qt"
if ${ssh} : &>/dev/null; then
  log "Confirmed SSH access to machine"
else
  # (manual) Enable ssh access with password or ssh key
  die "Set up SSH access to '${ip}' (either password or public key)"
fi

${ssh} sudo parted -l 2>&1 | indent
if confirm "Create new partition table (ALL DATA WILL BE LOST)?"; then
  ask "Partition which disk?" disk
  while ! ${ssh} sudo parted -s "${disk}" print &>/dev/null; do
    ask "'${disk}' does not exist; partition which disk?" disk
  done
  (${ssh} sudo parted -s ${disk} \
          mklabel gpt \
          mkpart ${hostname}-boot fat32 1MiB 1GiB \
          mkpart ${hostname}-root 1GiB 100% \
          set 1 esp 2>&1) | indent
fi
# - (confirm) create new partition table?

#   - create partition table

#   - create boot partition 1G

#   - create luks partition with free space

# - scp host public key -> age/keys/bootstrap.pub

# - re-encrypt secrets

# - (confirm) create a temporary branch

# - commit and push secrets

# - scp script

# - scp log

# - remotely execute script in phase 2 with log redirection


## Phose 2

# - validate arguments: hostname

# - (confirm) format unformatted boot partition, or re-format formatted boot
# partition?

#   - format boot parition as FAT32

# - (confirm) luksFormat unformatted luks partition, or re-luksFormat formatted
# luks partition?








# function die {
#   echo "${1}"
#   exit 1
# }

# function heading {
#   echo "== ${1}"
# }

# function log {
#   echo "-- ${1}"
# }

# function ask() {
#   msg="?? ${1} "
#   if [[ -v 2 ]]; then
#     read -p "${msg}" ${2}
#   else
#     read -p "${msg}"
#   fi
#   # prevents bunching in the log (because input is not logged)
#   echo
# }

# function confirm () {
#   ask "${1} (y/N)"
#   if [[ ${REPLY} =~ ^[Yy].* ]]; then
#     return 0
#   else
#     return 1
#   fi
# }

# function confirm_confirm () {
#   ask "${1} (yes/NO)"
#   if [[ ! ${REPLY} =~ ^[Yy][Ee][Ss]$ ]]; then
#     return 1
#   fi
#   return 0
# }

# scriptdir=$(dirname $(realpath "${0}"))
# agenix="github:ryantm/agenix?rev=03b51fe8e459a946c4b88dcfb6446e45efb2c24e"
# scpargs=("-o UserKnownHostsFile /dev/null" "-o StrictHostKeyChecking no")
# ###
# ## Validate arguments
# ###
# ([[ -v 1 ]] && ping -c 1 "${1}" &>/dev/null) \
  #   || die "Expected IP address as first argument"
# [[ -v 2 ]] || die "Expected hostname as second argument"
# ([[ -v 3 ]] && [[ -f "${scriptdir}/${3}" ]]) || \
  #   die "Expected config script as third argument"

# ip="${1}"
# hostname="${2}"
# configscript="${3}"

# ## Verify clean git status
# if (output=$(git status --porcelain) && [[ -z "${output}" ]]) &>/dev/null; then
#   log "Working directory is clean"
# else
#   die "Working directory is not clean"
# fi

# ## Use host branch, if available
# if (git branch -a --list | grep "${hostname}") &>/dev/null; then
#   log "Checking out ${hostname} branch"
#   git checkout "${hostname}"
# else
#   log "Already on ${hostname} branch"
# fi

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
