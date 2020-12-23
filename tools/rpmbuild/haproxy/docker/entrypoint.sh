#!/bin/bash -e

haproxy_url="$1"

if [ -z "${haproxy_url}" ]
then
  echo "Please pass haproxy source URL" >&2
  exit 1
fi

haproxy_tar_name="$(basename ${haproxy_url})"

workspace="/root/rpmbuild"
target="/target"

mkdir -p "${workspace}/"{BUILD,RPMS,SOURCES,SPECS,SRPMS}


cd ${workspace}/SOURCES
echo "fetching ${haproxy_url}"

curl -L --progress-bar --output "${haproxy_tar_name}" "${haproxy_url}"
tar xzvf "${haproxy_tar_name}"
cp /haproxy.spec ../SPECS/

cp /haproxy.service haproxy*/

cd ${workspace}/SPECS
rpmbuild -ba haproxy.spec

find "${workspace}/RPMS" -name '*.rpm' -exec cp {} "${target}" \;
