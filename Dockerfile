FROM fedora:34
LABEL maintainer="skipperTux"

ARG CLOUDBOX_NAME=cloudbox
ARG CLOUDBOX_VERSION
ARG ROOT_USER=root
ARG CLOUDBOX_USER=cloudbox
ARG DOCKER_USER=${CLOUDBOX_USER}
ARG CLOUDBOX_SSH=/home/${CLOUDBOX_USER}/.ssh
ARG CLOUDBOX_HOST_SSH=/home/${CLOUDBOX_USER}/host_ssh
ARG SSH=${CLOUDBOX_SSH}
ARG HOST_SSH=${CLOUDBOX_HOST_SSH}
ARG CLOUDBOX_WORKDIR=/home/${CLOUDBOX_USER}/Projects
ARG PROJECTS=${CLOUDBOX_WORKDIR}
ARG TERRAFORM_VERSION=0.15.2
ARG TERRAFORM_URI=terraform_${TERRAFORM_VERSION}_linux_amd64.zip
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_URI}
ARG TERRAFORM_BIN_PATH=/usr/local/bin
ARG PIP_PACKAGES="ansible==2.10 awscli dnspython lxml netaddr pypsexec pywinrm pywinrm[credssp]"
ARG BUILD_DATE

# Labels -- See https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.url="https://github.com/skipperTux/cloudbox"
LABEL org.opencontainers.image.version="${CLOUDBOX_VERSION}"
LABEL org.opencontainers.image.vendor="roeper.biz"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL org.opencontainers.image.title="${CLOUDBOX_NAME}"
LABEL org.opencontainers.image.description="Tooling for Terraform, Ansible, Kubernetes, AWS, Azure and Google Cloud in a Fedora based Docker/Podman image."

USER ${ROOT_USER}
# Install requirements
WORKDIR /tmp
# Google Cloud SDK repo
RUN echo -e '[google-cloud-sdk]\n\
name=Google Cloud SDK\n\
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\n\
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'\
  >> /etc/yum.repos.d/google-cloud-sdk.repo \
# Microsoft repository key
  && rpm --import https://packages.microsoft.com/keys/microsoft.asc \
# Microsoft Azure CLI repo
  && echo -e '[azure-cli]\n\
name=Azure CLI\n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc'\
  >> /etc/yum.repos.d/azure-cli.repo \
  && dnf -y --refresh upgrade \
  && dnf -y install \
    sudo \
    which \
    less \
    curl \
    unzip \
    openssh-clients \
    python3 \
# Google Cloud SDK
    google-cloud-sdk \
# kubectl
    kubectl \
# Microsoft Azure CLI
    azure-cli \
# Clean dnf cache
  && dnf clean all \
# Install Terraform
  && curl -sSLO ${TERRAFORM_URL} \
  && unzip ${TERRAFORM_URI} -d ${TERRAFORM_BIN_PATH} \
# Disable requiretty.
  && sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers \
# Add non-root user
  && useradd -m -s /bin/bash -U ${DOCKER_USER}

# Switch to non-root user
USER ${DOCKER_USER}
# Add .local/bin path and switch to workdir
# Fancy bash prompt PS1 see https://gist.github.com/scmx/242caa249b0ea343e2588adea14479e6
RUN echo -e '\n# User specific environment and startup programs\n\
PATH=$PATH:$HOME/.local/bin:$HOME/bin\n\
PS1='"'"'[🐳 \[\033[1;37m\]\u\[\033[0m\]@\[\033[1;36m\]\h \[\033[1;34m\]\W\[\033[0m\]]$ \[\033[0m\]'"'"'\n\
export PROMPT_COMMAND="history -a ; ${PROMPT_COMMAND:-:}"\n\
export HISTCONTROL=erasedups:ignorespace\n\
export HISTSIZE=16000\n\
export HISTIGNORE='"'"'&:clear:exit:history:ll:ls'"'"\
  >> ~/.bashrc \
# pip3
  && python3 -m ensurepip --upgrade \
# pip packages (Ansible, AWS CLI)
  && python3 -m pip install --upgrade --no-warn-script-location --user wheel \
  && python3 -m pip install --upgrade --no-warn-script-location --user ${PIP_PACKAGES} \
# Add .ssh from host
  && mkdir -p ${HOST_SSH} \
  && ln -s ${HOST_SSH} ${SSH} \
# Add mount volume
  && mkdir -p ${PROJECTS}

WORKDIR ${PROJECTS}
CMD ["/usr/sbin/init"]
