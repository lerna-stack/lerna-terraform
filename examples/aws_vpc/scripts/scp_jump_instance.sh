#!/usr/bin/env bash

scp -i "$(terraform output -raw ssh_private_key_filepath)" "$1" "$(terraform output -raw jump_instance_username)@$(terraform output -raw jump_instance_id):~"
