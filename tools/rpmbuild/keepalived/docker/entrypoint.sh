#!/bin/bash -e

keepalived_url="$1"
keepalived_branch="$2"

if [ -z "${keepalived_url}" ]
then
  echo "Please pass keepalived source URL" >&2
  exit 1
fi

keepalived_tar_name="$(basename ${keepalived_url})"

workspace="/root/rpmbuild"
target="/target"

mkdir -p "${workspace}/"{BUILD,RPMS,SOURCES,SPECS,SRPMS}

cd "${workspace}"

echo "fetching ${keepalived_url}"

curl -L --progress-bar --output "${keepalived_tar_name}" "${keepalived_url}"
tar xvf "${keepalived_tar_name}" --strip=1

cp /keepalived.service.in keepalived/keepalived.service.in

./build_setup
./configure --with-init=systemd
make rpm

find "${workspace}/RPMS" -name '*.rpm' -exec cp {} "${target}" \;
