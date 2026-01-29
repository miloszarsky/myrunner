# myrunner
Docker environment for running ansible and opentofu

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

```alias myrunner='docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v ~/.bash_history:/home/runner/.bash_history -v ~/.ssh:/home/runner/.ssh -v $(pwd):/mnt -v $(readlink -f $SSH_AUTH_SOCK):/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock --network host -e RUNNER_UID=$(id -u) -e RUNNER_GID=$(id -g) myrunner:latest "$@"'```

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
