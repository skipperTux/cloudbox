#!/usr/bin/env bash
if [ $UID -ne 0 ]; then
    echo "use: sudo ${0##*/}"
    exit -1
fi

# Set magic variables for current file & dir
__dir=`dirname "$(readlink -f "$0")"`
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__bin="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

binaries=("cloudctl" "kubectl" "terraform")
link_target="${__dir}"
link_name='/usr/local/bin'

for binary in ${binaries[@]}; do
   ln -s "${link_target}/${binary}" "${link_name}/${binary}" 2>/dev/null
done
