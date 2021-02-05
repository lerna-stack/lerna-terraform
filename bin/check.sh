#!/usr/bin/env bash

set -eux

terraform fmt -recursive -check

bin/validate-tf.sh modules/service/centos/core/
bin/validate-tf.sh modules/service/centos/dev/
bin/validate-tf.sh modules/platform/aws/ec2/
bin/validate-tf.sh examples/aws_ec2/
bin/validate-tf.sh examples/aws_vpc/

bin/generate-variables-example.sh check-module-template   modules/service/centos/core/variables.tf
bin/generate-variables-example.sh check-module-template   modules/service/centos/dev/variables.tf
bin/generate-variables-example.sh check-module-template   modules/platform/aws/ec2/variables.tf
bin/generate-variables-example.sh check-tfvars            examples/aws_ec2/variables.tf
bin/generate-variables-example.sh check-tfvars            examples/aws_vpc/variables.tf
