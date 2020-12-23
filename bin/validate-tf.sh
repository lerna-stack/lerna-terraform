#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Argument is missing. Please set 1 argument(target dir)."
  exit 1
fi

TARGET_DIR=${1}

cd $TARGET_DIR || exit 1

terraform init
terraform validate
