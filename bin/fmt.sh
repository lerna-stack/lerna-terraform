#!/usr/bin/env bash

set -eux

terraform fmt -recursive

bin/generate-variables-example.sh generate-module-template   modules/service/redhat/core/variables.tf
bin/generate-variables-example.sh generate-module-template   modules/service/redhat/dev/variables.tf
bin/generate-variables-example.sh generate-module-template   modules/platform/aws/ec2/variables.tf
bin/generate-variables-example.sh generate-tfvars            examples/aws_ec2/variables.tf
bin/generate-variables-example.sh generate-tfvars            examples/aws_vpc/variables.tf
