locals {
  all_instance_ips = concat(
    module.lerna_stack_platform_aws_ec2.keepalived_instance_ips,
    module.lerna_stack_platform_aws_ec2.haproxy_instance_ips,
    module.lerna_stack_platform_aws_ec2.app_instance_ips,
    module.lerna_stack_platform_aws_ec2.cassandra_instance_ips,
    module.lerna_stack_platform_aws_ec2.mariadb_instance_ips,
  )
}
