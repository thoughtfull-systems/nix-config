#!/usr/bin/env bash

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

function ask() {
  msg="?? ${1} "
  if [[ -v 2 ]]; then
    read -p "${msg}" ${2}
  else
    read -p "${msg}"
  fi
  # prevents bunching in the log (because input is not logged)
  echo
}

function confirm () {
  ask "${1} (y/N)"
  if [[ ${REPLY} =~ ^[Yy].* ]]; then
    return 0
  else
    return 1
  fi
}

function confirm_confirm () {
  ask "${1} (yes/NO)"
  if [[ ! ${REPLY} =~ ^[Yy][Ee][Ss]$ ]]; then
    return 1
  fi
  return 0
}
