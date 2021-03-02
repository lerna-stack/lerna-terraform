#!/bin/bash

readonly script_name="$(basename "$0")"

function main {

  case "$1" in
    '--help' )
      print_usage
      ;;
    '' )
      echo 'service name is empty' >&2
      print_usage
      ;;
    * )
      local service_name="$1"
      sudo systemctl daemon-reload
      sudo systemctl enable "${service_name}"
      ;;
  esac
}

function print_usage {
  cat - <<USAGE

systemd のサービスの自動起動を有効にします

使い方: ${script_name} [service_name]

service_name:
  systemd のサービス名

USAGE
}

main "$@"
