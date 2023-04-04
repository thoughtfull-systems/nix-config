#!/usr/bin/env -S bash -euo pipefail
scriptdir=$(realpath $(dirname $0))
cat "${scriptdir}/../names.txt" | grep -v '#' | shuf -n 1
