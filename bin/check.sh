#!/usr/bin/env bash

set -eux

terraform fmt -recursive -check

bin/validate-tf.sh modules/service/redhat/core/
bin/validate-tf.sh modules/service/redhat/dev/
bin/validate-tf.sh modules/platform/aws/ec2/
bin/validate-tf.sh examples/aws_ec2/
bin/validate-tf.sh examples/aws_vpc/

bin/generate-variables-example.sh check-module-template   modules/service/redhat/core/variables.tf
bin/generate-variables-example.sh check-module-template   modules/service/redhat/dev/variables.tf
bin/generate-variables-example.sh check-module-template   modules/platform/aws/ec2/variables.tf
bin/generate-variables-example.sh check-tfvars            examples/aws_ec2/variables.tf
bin/generate-variables-example.sh check-tfvars            examples/aws_vpc/variables.tf
