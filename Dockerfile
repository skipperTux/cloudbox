FROM centos:7
LABEL maintainer "skipperTux"

ARG CLOUDCTL_USER=bastion
ARG CLOUDCTL_WORKDIR=/home/${CLOUDCTL_USER}/Projects

ENV root_user root
ENV terraform_version 0.12.6
ENV terraform terraform_${terraform_version}_linux_amd64.zip
ENV terraform_bin_path /opt/terraform
ENV pip_packages="ansible awscli pypsexec pywinrm pywinrm[credssp]"
ENV docker_user ${CLOUDCTL_USER}
ENV projects ${CLOUDCTL_WORKDIR}

USER ${root_user}
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
      python-pip

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
RUN curl -sSLO https://releases.hashicorp.com/terraform/${terraform_version}/$terraform \
  && mkdir -p ${terraform_bin_path} \
  && unzip $terraform -d ${terraform_bin_path} \
  && echo 'PATH=$PATH:'${terraform_bin_path}'' > /etc/profile.d/terraform.sh

# Install Google Cloud SDK
RUN yum -y install google-cloud-sdk
# Install kubectl
RUN yum -y install kubectl

# Install Microsoft Azure CLI
RUN yum -y install azure-cli

# Add non-root user
RUN useradd -m -s /bin/bash -U ${docker_user}

USER ${docker_user}
# Install pip packages (Ansible, AWS CLI)
RUN pip install --upgrade --user ${pip_packages}

# Add mount volume
RUN mkdir -p ${projects}

USER ${root_user}
# Clean yum cache
RUN yum clean all

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers

# Switch to non-root user, add .local/bin path and switch to workdir
USER ${docker_user}
RUN echo -e '\n# User specific environment and startup programs\n\
PATH=$PATH:$HOME/.local/bin:$HOME/bin'\
  >> ~/.bashrc
WORKDIR ${projects}

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]