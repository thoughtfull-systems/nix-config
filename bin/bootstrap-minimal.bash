#!/usr/bin/env bash

set -exuo pipefail

function die {
  echo "${1}"
  exit 1
}

function heading {
  echo "== ${1}"
}

function log {
  echo "-- ${1}"
}

scriptdir=$(dirname $(realpath "${0}"))
agenix="github:ryantm/agenix?rev=03b51fe8e459a946c4b88dcfb6446e45efb2c24e"
scpargs=("-o UserKnownHostsFile /dev/null" "-o StrictHostKeyChecking no")

## Validate arguments
[[ -v 1 ]] || die "Expected IP address as first argument"
[[ -v 2 ]] || die "Expected hostname as second argument"
([[ -v 3 ]] && [[ -f "${scriptdir}/${3}" ]]) || \
  die "Expected config script as third argument"

ip="${1}"
hostname="${2}"
configscript="${3}"

## Verify clean git status
if (output=$(git status --porcelain) && [[ -z "${output}" ]]) &>/dev/null; then
  log "Working directory is clean"
else
  die "Working directory is not clean"
fi

## Use host branch, if available
if (git branch -a --list | grep "${hostname}") &>/dev/null; then
  log "Checking out ${hostname} branch"
  git checkout "${hostname}"
else
  log "Already on ${hostname} branch"
fi

heading "BEGIN bootstrapping $(date)"

## Download SSH host public key
tempdir=$(mktemp -d)
tempfile="${tempdir}/ssh_host_ed25519_key.pub"
bootstrapfile="${scriptdir}/../age/keys/bootstrap.pub"
log "Copying bootstrap key to ${tempfile}"
scp "${scpargs[@]}" "nixos@${ip}:/etc/ssh/ssh_host_ed25519_key.pub" "${tempdir}"
if [[ $(cat "${tempfile}") != $(cat "${bootstrapfile}") ]]; then
  log "Replacing ${bootstrapfile} with ${tempfile}"
  mv "${tempfile}" "${bootstrapfile}"

  ## Re-key secrets
  pushd "${scriptdir}/../age"
  nix run "${agenix}" -- -r -i "decrypt-identity.txt"
  popd

  ## Commit and push new secrets
  git add age/secrets
  git commit -m"Bootstrapping ${hostname}"
  git push
else
  log "Using ${bootstrapfile} as is"
  rm "${tempfile}"
fi

ssh "${scpargs[@]}" "nixos@${ip}" \
    sudo cp /etc/ssh/ssh_host_ed25519_key /tmp/bootstrap.key

## SCP bootstrap script
scp "${scpargs[@]}" "${scriptdir}/${configscript}" "nixos@${ip}:${configscript}"

## SSH and execute bootstrap script
ssh "${scpargs[@]}" -t "nixos@${ip}" sudo bash "${configscript}" "${hostname}"

heading "END bootstrapping $(date)"
