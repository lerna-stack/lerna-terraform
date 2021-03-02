#!/bin/bash

readonly server_private_key='server-private-key.pem'
readonly server_csr='lerna.test.csr'
readonly server_crt='lerna.test.crt'
readonly server_pem='lerna.test.pem'

function main {
  set -ex

  openssl genrsa -out "${server_private_key}" 2048
  openssl req -new -subj '//CN=Lerna' -key "${server_private_key}" -out "${server_csr}"
  openssl x509 -days 36500 -req -in "${server_csr}" -signkey "${server_private_key}" -out "${server_crt}"

  cat "${server_crt}" "${server_private_key}" > "${server_pem}"
}

main
