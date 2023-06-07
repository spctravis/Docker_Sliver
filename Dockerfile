FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

ENV pip_packages "ansible cryptography"

# Install dependencies.
RUN apt-get update \
    && apt-get install -y -s --no-install-recommends \
       build-essential \
       iproute2 \
       libffi-dev \
       libssl-dev \
       python3-apt \
       python3-dev \
       python3-pip \
       python3-setuptools \
       python3-wheel \
       sudo \
       systemd \
       systemd-sysv \
       wget \
       bloodhound \
       mingw-w64-* \
       binutils-mingw-w64 \
       dnsmasq \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean

# Install Sliver
RUN curl https://sliver.sh/install | sudo bash
COPY sliver.service /etc/systemd/system/sliver.service
RUN chmod 600 /etc/systemd/system/sliver.service
#RUN alias sliver=/opt/sliver/sliver-client_linux
RUN chmod a+x ./sliver_user_config
RUN sudo ./sliver_user_config kali 127.0.0.1
RUN chown kali kali.config
RUN service sliver enable
RUN service sliver start
RUN /opt/sliver/sliver-client_linux
RUN armory install all
RUN exit

# Install Ansible via pip.
RUN pip3 install --break-system-packages $pip_packages

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Make sure systemd doesn't start agettys on tty[1-6].
RUN rm -f /lib/systemd/system/multi-user.target.wants/getty.target

VOLUME ["/sys/fs/cgroup"]
CMD ["/lib/systemd/systemd"]
