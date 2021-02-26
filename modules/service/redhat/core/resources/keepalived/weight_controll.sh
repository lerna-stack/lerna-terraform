#!/bin/bash

server_name="$1"
base_path='/etc/keepalived/real_servers'

if [[ -z "${server_name}" ]]
then
  echo 'server name is not specified' >&2
  exit 1
fi

# Real server status file
status_file="${base_path}/${server_name}.status"

# '#' で始まるコメントと空白・空行はトリム
server_is_status="$(cat "${status_file}" | sed -E -e 's/#.*$//g' -e 's/^ *//g' -e 's/ *$//g' -e '/^$/d')"

case "${server_is_status}" in
  'active' )   exit 0 ;;
  'inactive' ) exit 1 ;;
  *)
    echo "不正なステータス: ${server_is_status}" >&2
    exit 404
    ;;
esac
