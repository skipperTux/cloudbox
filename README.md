# cloudbox

Tooling for Terraform, Ansible, Kubernetes, AWS, Azure and Google Cloud in a [Fedora](https://hub.docker.com/_/fedora) based Docker/Podman image. The image can be used with the [Visual Studio Code Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension and supports various in-container extensions like [Azure Tools for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack) [Visual Studio Code Kubernetes Tools](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools), [Terraform Visual Studio Code Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform) etc. When [Visual Studio Code supports *Fedora Toolbox*](https://github.com/microsoft/vscode-remote-release/issues/3345) this image might be replaced with a Toolbox setup with all Cloud-tools installed via Ansible.

## cloudctl

### All available options

```text
Usage: cloudctl [OPTION]...

-b, --build                     Build image from Dockerfile
-f, --force                     Do not use cache when building the image. Only useful with build option.
-d, --docker                    Use Docker CLI instead of Podman
-e COMMAND, --exec COMMAND,
-e=COMMAND, --exec=COMMAND      Run COMMAND in runnning container 'cloudctl'
no option                       Create container 'cloudctl' and start a Bash session
-h, --help                      print help
```

Use

```bash
export CONTAINER_ALIAS='{ docker | podman }'
```

to set the Container Engine CLI for the current terminal session.

### Build image

Build image using build cache.

```bash
cloudctl --build
cloudctl -b  # short version
```

Rebuild image not using the cache at all.

```bash
cloudctl --build --force
cloudctl -b -f  # short version
```

For more information about the build cache see [Leverage build cache](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache) in the Docker Documentation.

### Create container and run Bash session

```bash
cloudctl
```

### Run COMMAND in container

```bash
# run kubectl in container
cloudctl --exec=kubectl
cloudctl -e kubectl  # short version

# run kubectl with args
cloudctl --exec 'kubectl version'
cloudctl -e='kubectl version'  # short version
```

Commands with spaces need to be quoted.

### Run cloudctl as non-root user

If you do not want to preface `cloudctl` with `sudo`, there are options, see [Manage Docker as a non-root user](https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user). However this impacts security in your system, see [Docker Daemon Attack Surface](https://docs.docker.com/engine/security/security/#docker-daemon-attack-surface).
A better option is to use a rootless container tool like [Podman](https://github.com/containers/libpod/blob/master/docs/tutorials/rootless_tutorial.md). After basic setup of [Podman in a Rootless environment](https://github.com/containers/libpod/blob/master/docs/tutorials/rootless_tutorial.md), this can simply be done via `alias docker=podman`.

### Project directory

The host user's `${HOME}/Projects` directory is mounted into `/home/${CLOUDBOX_USER}/Projects` in the container.

If your current/working directory `${PWD}` in your IDE or Terminal on the host machine is within that Projects folder, `cloudctl` changes into that directory on start.

### SSH keys

The host user's `${HOME}/.ssh` directory is mounted into `/home/${CLOUDBOX_USER}/host_ssh` in the container, and a symbolic link is created to the cloudbox user's `.ssh` directory.

If you want to use different ssh keys coming with your project, delete the link and create a new link to a ssh directory in your project:

```bash
[bastion]$ rm -f ~/.ssh
[bastion]$ ln -s ~/Projects/devOpsProject/ssh .ssh
```

## Available tools

### [Terraform](https://www.terraform.io/intro/)

```bash
[bastion]$ terraform version
```

### [Ansible](https://docs.ansible.com/)

```bash
[bastion]$ ansible --version
```

Ansible is using Python 3 and has the following modules installed: dnspython, lxml, netaddr, pypsexec, pywinrm and pywinrm[credssp].

### <a name="kubernetes"></a> [Kubernetes](https://kubernetes.io/docs/home/)

```bash
[bastion]$ kubectl version
```

### [AWS Command Line Interface](https://aws.amazon.com/cli/)

```bash
[bastion]$ aws --version
```

### [Azure Command-Line Interface (CLI)](https://docs.microsoft.com/en-us/cli/azure/)

```bash
[bastion]$ az --version
```

### [Google Cloud Platform - Cloud SDK](https://cloud.google.com/sdk/)

#### gcloud command-line tool

```bash
[bastion]$ gcloud version
```

#### gsutil tool

```bash
[bastion]$ gsutil version
```

#### kubectl tool

See [Kubernetes](#kubernetes).

#### bq tool

```bash
[bastion]$ bq version
```

## kubectl

Sample Shim (Bash script) to provide `kubectl` in your host system. Simply set a link to - or copy - the shim to a directory in your `${PATH}`:

```bash
chmod +x kubectl
ln -s /usr/local/bin/kubectl kubectl
```

and tools in your host IDE, e.g. [Visual Studio Code Kubernetes Tools](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools), can find the Kubernetes _binary_.
