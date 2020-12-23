#!/usr/bin/env bash

ssh -i "$(terraform output -raw ssh_private_key_filepath)" "$(terraform output -raw jump_instance_username)@$(terraform output -raw jump_instance_id)"
