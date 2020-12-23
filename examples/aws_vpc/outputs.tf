output "aws_internet_gateway_id" {
  value = local.igw_id
}
output "aws_keepalived_instance_role_name" {
  value = module.security.keepalived_instance_iam_role_id
}
output "aws_vpc_id" {
  value = local.vpc_id
}
output "aws_vpc_nat_gateway_id" {
  value = local.natgw_id
}
output "aws_vpc_route_table_id_for_virtual_ips" {
  value = local.private_route_table_id
}
output "aws_vpc_security_group_id" {
  value = local.security_group_id
}
output "aws_vpc_subnet_id" {
  value = local.private_subnet_id
}
output "jump_instance_id" {
  value = module.jump_instance.id
}
output "jump_instance_username" {
  value = local.jump_instance_username
}
output "ssh_private_key_filepath" {
  value = local.ssh_private_key_filepath
}
