#!/bin/bash

cd "$(dirname $0)"

mkdir -p target

cd docker
docker-compose run \
  --rm \
  keepalived-rpmbuild https://www.keepalived.org/software/keepalived-2.0.16.tar.gz
