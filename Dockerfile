FROM debian:bookworm-slim
LABEL maintainer="Milos Zarsky"

ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       sudo systemd systemd-sysv gnupg software-properties-common \
       wget whois fping less net-tools curl unzip inetutils-ping ssh git jq nano vim rsync \
       mc bash-completion dnsutils genisoimage \
       python3 python3-pip python3-venv sshpass python3-netaddr \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean
 
ENV PATH=/opt/.venv/bin:$PATH
RUN mkdir -p /opt/ansible && mkdir -p /etc/ansible
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config

#OpenTofu
# Download the installer script:
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

# Give it execution permissions:
RUN chmod +x install-opentofu.sh

# Run the installer:
RUN ./install-opentofu.sh --install-method deb

# Remove the installer:
RUN rm install-opentofu.sh

#aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip
RUN ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install SOPS
RUN SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') \
    && curl -LO "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops_${SOPS_VERSION}_amd64.deb" \
    && dpkg -i "sops_${SOPS_VERSION}_amd64.deb" \
    && rm "sops_${SOPS_VERSION}_amd64.deb"

# Install age
RUN AGE_VERSION=$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO "https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz" \
    && tar -xf "age-${AGE_VERSION}-linux-amd64.tar.gz" \
    && mv age/age age/age-keygen /usr/local/bin/ \
    && rm -rf age "age-${AGE_VERSION}-linux-amd64.tar.gz"

RUN set -x \
    && echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/runner \
    && echo "net.ipv4.ping_group_range = 0 2147483647" >> /etc/sysctl.conf \
    && usermod --shell /bin/bash root

COPY entrypoint.sh /entrypoint.sh
COPY requirements.txt .
COPY motd /etc/motd
COPY ansible.cfg /etc/ansible/ansible.cfg
RUN chmod 644 /etc/ansible/ansible.cfg

RUN python3 -m venv /opt/.venv
RUN . /opt/.venv/bin/activate && pip install -r requirements.txt \
    && ansible-galaxy collection install ansible.posix \
    && ansible-galaxy collection install ansible.utils \
    && ansible-galaxy collection install ansible.netcommon \
    && ansible-galaxy collection install community.network \
    && ansible-galaxy collection install community.mysql \
    && ansible-galaxy collection install community.general \
    && ansible-galaxy collection install community.crypto \
    && ansible-galaxy collection install community.postgresql \
    && ansible-galaxy collection install community.docker \
    && ansible-galaxy collection install community.mongodb

WORKDIR /mnt
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]
