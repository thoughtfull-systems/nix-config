#!/usr/bin/env sh
v=82
while [ ${v} -eq 82 ]; do
  emacs -f exwm-enable
  v=${?}
done
exit ${v}
