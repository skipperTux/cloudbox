#!/bin/bash
if [ $UID -ne 0 ]; then
    echo "use: sudo ${0##*/}"
    exit -1
fi

export CLOUD_BASTION_USER='bastion'
export CLOUD_BASTION_SSH="/home/${CLOUD_BASTION_USER}/.ssh"
export CLOUD_BASTION_WORKDIR="/home/${CLOUD_BASTION_USER}/Projects"
LOCAL_HOME="$(getent passwd ${SUDO_USER} | cut -d: -f6)"
LOCAL_WORKDIR="${LOCAL_HOME}/Projects"
LOCAL_SSH="${LOCAL_WORKDIR}/ssh"

# Create local working directories
sudo -H -u ${SUDO_USER} mkdir -p ${LOCAL_WORKDIR}
sudo -H -u ${SUDO_USER} mkdir -p ${LOCAL_SSH}

while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # This is a flag type option. Will catch either -b or --build
        -b|--build)
        build=true
        ;;
        *)
        # Do whatever you want with extra options
        echo "Unknown option '$key'"
        ;;
    esac
    shift
done

# Start Docker service, if not running (systemd)
if ! systemctl is-active --quiet docker; then
    systemctl start --quiet docker
fi

# Build cloud-bastion image
if [ "$build" = true ] ; then
    pushd `dirname "$(readlink -f "$0")"`
    docker build \
        --rm \
        --build-arg CLOUD_BASTION_USER=${CLOUD_BASTION_USER} \
        --build-arg CLOUD_BASTION_WORKDIR=${CLOUD_BASTION_WORKDIR} \
        -t local/cloud-bastion .
    popd
fi

# Run cloud-bastion container
docker run \
    -it \
    --mount type=bind,source="${LOCAL_WORKDIR}",target="${CLOUD_BASTION_WORKDIR}" \
    --mount type=bind,source="${LOCAL_SSH}",target="${CLOUD_BASTION_SSH}" \
    local/cloud-bastion /bin/bash