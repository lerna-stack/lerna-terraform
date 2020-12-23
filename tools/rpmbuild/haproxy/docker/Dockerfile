FROM centos:centos7

RUN yum install -y \
  curl \
  tar \
  rpm-build \
  autoconf \
  automake \
  make \
  gcc \
  openssl-devel \
  popt-devel \
  kernel \
  kernel-devel \
  ipvsadm \
  libnl3-devel \
  net-snmp-devel \
  libnfnetlink-devel \
  pcre-static \
  pcre-devel \
  && yum clean all

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x      /entrypoint.sh
ADD haproxy.service /haproxy.service

VOLUME ["/root/rpmbuild", "/target"]

ENTRYPOINT ["/entrypoint.sh"]
