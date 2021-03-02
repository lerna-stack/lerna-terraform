#!/bin/bash

function main {
  case "$1" in
    '--help' )
      print_usage
      ;;
    * )
      sudo yum localinstall "$@"
      ;;
  esac
}

function print_usage {
  cat - <<USAGE

yum localinstall コマンドを特権で実行します

##################################################
# yum localinstall --help
##################################################
$(yum localinstall --help)
USAGE
}

main "$@"
