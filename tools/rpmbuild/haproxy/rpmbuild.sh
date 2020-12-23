#!/bin/bash

cd "$(dirname $0)"

mkdir -p target

cd docker
docker-compose run --rm haproxy-rpmbuild https://www.haproxy.org/download/2.0/src/haproxy-2.0.13.tar.gz
