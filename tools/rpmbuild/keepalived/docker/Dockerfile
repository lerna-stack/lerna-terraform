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
  && yum clean all

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x      /entrypoint.sh
ADD keepalived.service.in /keepalived.service.in

VOLUME ["/root/rpmbuild", "/target"]

ENTRYPOINT ["/entrypoint.sh"]
