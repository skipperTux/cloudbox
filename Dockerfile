FROM centos:7
LABEL maintainer="skipperTux"

ARG ROOT_USER=root
ARG CLOUDCTL_USER=bastion
ARG DOCKER_USER=${CLOUDCTL_USER}
ARG CLOUDCTL_SSH=/home/${CLOUDCTL_USER}/.ssh
ARG CLOUDCTL_HOST_SSH=/home/${CLOUDCTL_USER}/host_ssh
ARG SSH=${CLOUDCTL_SSH}
ARG HOST_SSH=${CLOUDCTL_HOST_SSH}
ARG CLOUDCTL_WORKDIR=/home/${CLOUDCTL_USER}/Projects
ARG PROJECTS=${CLOUDCTL_WORKDIR}
ARG TERRAFORM_VERSION=0.12.6
ARG TERRAFORM_URI=terraform_${TERRAFORM_VERSION}_linux_amd64.zip
ARG TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_URI}
ARG TERRAFORM_BIN_PATH=/opt/terraform
ARG PIP_PACKAGES="ansible awscli lxml netaddr pypsexec pywinrm pywinrm[credssp]"
ARG BUILD_DATE

# Labels -- See https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.url="https://github.com/skipperTux/cloud-bastion"
LABEL org.opencontainers.image.version="0.2.1"
LABEL org.opencontainers.image.vendor="roeper.biz"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL org.opencontainers.image.title="cloud-bastion"
LABEL org.opencontainers.image.description="Tooling for Terraform, Ansible, Kubernetes, AWS, Azure and Google Cloud in a CentOS 7 based Docker image."

USER ${ROOT_USER}
# Install systemd -- See https://hub.docker.com/_/centos
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install requirements
RUN yum makecache fast \
  && yum -y install deltarpm epel-release initscripts \
  && yum -y update \
  && yum -y install \
      sudo \
      which \
      less \
      curl \
      unzip \
      openssh-clients \
      python36

# Install pip3
RUN python3 -m ensurepip

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
RUN yum -y update

# Install Terraform
WORKDIR /tmp
RUN curl -sSLO ${TERRAFORM_URL} \
  && mkdir -p ${TERRAFORM_BIN_PATH} \
  && unzip ${TERRAFORM_URI} -d ${TERRAFORM_BIN_PATH} \
  && echo 'PATH=$PATH:'${TERRAFORM_BIN_PATH}'' > /etc/profile.d/terraform.sh

# Install Google Cloud SDK
RUN yum -y install google-cloud-sdk
# Install kubectl
RUN yum -y install kubectl

# Install Microsoft Azure CLI
RUN yum -y install azure-cli

# Add non-root user
RUN useradd -m -s /bin/bash -U ${DOCKER_USER}

USER ${DOCKER_USER}
# Install pip packages (Ansible, AWS CLI)
RUN pip3 install --upgrade --user ${PIP_PACKAGES}

# Add .ssh from host
RUN mkdir -p ${HOST_SSH} \
  && ln -s ${HOST_SSH} ${SSH}

# Add mount volume
RUN mkdir -p ${PROJECTS}

USER ${ROOT_USER}
# Clean yum cache
RUN yum clean all

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers

# Switch to non-root user, add .local/bin path and switch to workdir
USER ${DOCKER_USER}
RUN echo -e '\n# User specific environment and startup programs\n\
PATH=$PATH:$HOME/.local/bin:$HOME/bin'\
  >> ~/.bashrc
WORKDIR ${PROJECTS}

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]