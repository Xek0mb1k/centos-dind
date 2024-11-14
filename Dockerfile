FROM quay.io/centos/centos:stream8
# UPdATE REPO LIST
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo \
    && sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum update -y \
    && yum install sudo -y
RUN set -eux; \
  yum install -y epel-release; \
  yum install -y \
    e2fsprogs \
    git \
    iptables \
    openssl \
    pigz \
    shadow-utils \
    xfsprogs \
    xz \
  ; \
  yum clean all

# Установка iptables legacy
RUN set -eux; \
  yum install -y iptables-services; \
  ln -s /usr/sbin/iptables-legacy /usr/bin/iptables; \
  ln -s /usr/sbin/ip6tables-legacy /usr/bin/ip6tables;
  
# Настройка subuid/subgid для корректной работы userns-remap
RUN set -eux; \
  groupadd --system dockremap; \
  useradd --system --gid dockremap dockremap; \
  echo 'dockremap:165536:65536' >> /etc/subuid; \
  echo 'dockremap:165536:65536' >> /etc/subgid

# Установка Docker
RUN set -eux; \
  yum install -y yum-utils;\
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo; \
  yum install -y wget; \
  yum install -y iptables; \
  url='https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz'; \
  wget -O 'docker.tgz' "$url"; \
  tar --extract \
    --file docker.tgz \
    --strip-components 1 \
    --directory /usr/local/bin/ \
    --no-same-owner \
    --exclude 'docker/docker' \
  ; \
  rm docker.tgz; \
  dockerd --version; \
  containerd --version; \
  ctr --version; \
  runc --version

# Установка dind
ENV DIND_COMMIT 65cfcc28ab37cb75e1560e4b4738719c07c6618e
RUN set -eux; \
  wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
  chmod +x /usr/local/bin/dind

COPY dockerd-entrypoint.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

RUN yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]

