#!/usr/bin/env -S bash -euo pipefail
logfile=$(mktemp)
echo "#### Temporary log file '${logfile}'"
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1> >(tee ${logfile}) 2>&1

#### EVERYTHING BELOW WILL GO TO TERMINAL AND LOGFILE ####

echo "Hello, World! $(realpath $0)"
# '2>&3' means don't log prompt (neither is response logged)
read -p "foo: " 2>&3
echo "blah"
#echo "echo \"test\"" >>$(realpath $0)
