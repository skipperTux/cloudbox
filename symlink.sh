#!/usr/bin/env bash
if [ $UID -ne 0 ]; then
    echo "use: sudo ${0##*/}"
    exit -1
fi

binaries=("cloudctl" "kubectl" "terraform")
link_target="${HOME}/Projects/container/cloudbox/"
link_name='/usr/local/bin/'

for binary in ${binaries[@]}; do
   ln -s "${link_target}${binary}" "${link_name}${binary}" 2>/dev/null
done