FROM centos:8
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
ARG TERRAFORM_VERSION=0.13.4
ARG TERRAFORM_URI=terraform_${TERRAFORM_VERSION}_linux_amd64.zip
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_URI}
ARG TERRAFORM_BIN_PATH=/usr/local/bin
ARG PIP_PACKAGES="ansible awscli dnspython lxml netaddr pypsexec pywinrm pywinrm[credssp]"
ARG BUILD_DATE

# Labels -- See https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.url="https://github.com/skipperTux/cloudbox"
LABEL org.opencontainers.image.version="${CLOUDBOX_VERSION}"
LABEL org.opencontainers.image.vendor="roeper.biz"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL org.opencontainers.image.title="${CLOUDBOX_NAME}"
LABEL org.opencontainers.image.description="Tooling for Terraform, Ansible, Kubernetes, AWS, Azure and Google Cloud in a CentOS 8 based Docker/Podman image."

USER ${ROOT_USER}

# Install requirements
RUN dnf makecache \
  && dnf -y upgrade --refresh \
  && dnf -y install \
    sudo \
    which \
    less \
    curl \
    unzip \
    openssh-clients \
    python3

# Add non-root user
RUN useradd -m -s /bin/bash -U ${DOCKER_USER}

USER ${DOCKER_USER}

# Install pip3
RUN python3 -m ensurepip

USER ${ROOT_USER}

# Google Cloud SDK repo
RUN echo -e '[google-cloud-sdk]\n\
name=Google Cloud SDK\n\
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\n\
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'\
  >> /etc/yum.repos.d/google-cloud-sdk.repo

# Microsoft repository key
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Microsoft Azure CLI repo
RUN echo -e '[azure-cli]\n\
name=Azure CLI\n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc'\
  >> /etc/yum.repos.d/azure-cli.repo

# Update system
RUN dnf -y update

# Install Terraform
WORKDIR /tmp
RUN curl -sSLO ${TERRAFORM_URL} \
  && unzip ${TERRAFORM_URI} -d ${TERRAFORM_BIN_PATH}

# Install Google Cloud SDK
RUN dnf -y install google-cloud-sdk
# Install kubectl
RUN dnf -y install kubectl

# Install Microsoft Azure CLI
RUN dnf -y install azure-cli

USER ${DOCKER_USER}
# Install pip packages (Ansible, AWS CLI)
RUN pip3 install --upgrade --user ${PIP_PACKAGES}

# Add .ssh from host
RUN mkdir -p ${HOST_SSH} \
  && ln -s ${HOST_SSH} ${SSH}

# Add mount volume
RUN mkdir -p ${PROJECTS}

USER ${ROOT_USER}
# Clean dnf cache
RUN dnf clean all

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers

# Switch to non-root user, add .local/bin path and switch to workdir
# Fancy bash prompt PS1 see https://gist.github.com/scmx/242caa249b0ea343e2588adea14479e6
USER ${DOCKER_USER}
RUN echo -e '\n# User specific environment and startup programs\n\
PATH=$PATH:$HOME/.local/bin:$HOME/bin\n\
PS1='"'"'[🐳 \[\033[1;37m\]\u\[\033[0m\]@\[\033[1;36m\]\h \[\033[1;34m\]\W\[\033[0m\]]$ \[\033[0m\]'"'"'\n\
export PROMPT_COMMAND="history -a ; ${PROMPT_COMMAND:-:}"\n\
export HISTCONTROL=erasedups:ignorespace\n\
export HISTSIZE=16000\n\
export HISTIGNORE='"'"'&:clear:exit:history:ll:ls'"'"\
  >> ~/.bashrc
WORKDIR ${PROJECTS}

CMD ["/usr/sbin/init"]