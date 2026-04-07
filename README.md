# myrunner
Docker environment for running devops tools

## create alias in system
LINUX

.bashrc or .zshrc
```
unalias myrunner 2>/dev/null
myrunner() {
    # 1. Check if SSH_AUTH_SOCK is set to prevent the crash
    if [ -z "$SSH_AUTH_SOCK" ]; then
        echo "Error: SSH_AUTH_SOCK is not set, try to setup"
        eval "$(ssh-agent -s)"
        ssh-add
    fi

    # 2. Run the docker command
    docker run --rm -it \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v ~/.bash_history:/home/runner/.bash_history \
        -v ~/.ansible-ava.vault:/home/runner/.ansible-ava.vault \
        -v ~/.ssh:/home/runner/.ssh \
        -v ~/.sops:/home/runner/.sops \
        -v ~/.kube:/home/runner/.kube \
        -v "$(pwd)":/mnt \
        -v "$(readlink -f "$SSH_AUTH_SOCK")":/run/host-services/ssh-auth.sock \
        -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
        --network host \
        -e RUNNER_UID="$(id -u)" \
        -e RUNNER_GID="$(id -g)" \
        ghcr.io/miloszarsky/myrunner:latest "$@"
}
```

MACOS

```alias myrunner='d() { docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v ~/.bash_history:/home/runner/.bash_history -v ~/.ssh:/home/runner/.ssh -v $(pwd):/mnt -v $(readlink -f $SSH_AUTH_SOCK):/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock --network host -e RUNNER_UID=$(id -u) -e RUNNER_GID=$(id -g) myrunner:latest "$@" };d'```

WINDOWS

```
alias myrunner='podman run --rm -it `
 -v //var/run/docker.sock:/var/run/docker.sock `
 -v "$HOME\.ssh:/home/runner/.ssh" `
 -v "$($PWD.Path):/mnt" `
 --network host `
 -e RUNNER_UID=1000 `
 -e RUNNER_GID=1000 `
 ghcr.io/miloszarsky/myrunner:latest $arg'
```

## usage

 * ```cd \<directory of your ansible project>```

 * (container mounts actual directory)

RUN

without arguments will run /bin/bash

run ansible-playbook directly
eg.:
```
myrunner ansible-playbook playbook.yml
```

## **Docker Build: Used Tools & Repositories**

| Tool | Repository / Source |
| --- | --- |
| **OpenTofu** | [opentofu/opentofu](https://github.com/opentofu/opentofu) |
| **sops** | [getsops/sops](https://github.com/getsops/sops) |
| **age** | [FiloSottile/age](https://github.com/FiloSottile/age) |
| **kubectl** | [kubernetes/kubectl](https://github.com/kubernetes/kubectl) |
| **Helm** | [helm/helm](https://github.com/helm/helm) |
| **AWS CLI** | [aws/aws-cli](https://github.com/aws/aws-cli) |
| **yq** | [mikefarah/yq](https://github.com/mikefarah/yq) |
