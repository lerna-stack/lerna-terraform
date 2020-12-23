variable "keepalived_route_table_owner_id" {
  type        = string
  description = "Owner ID of the route table"
  # example = "123456789012"
}
variable "keepalived_route_table_id" {
  type        = string
  description = "Route table ID that is edited by Keepalived instance"
  # example = "rtb-0123456789abcdef0"
}
variable "tags" {
  type        = map(string)
  description = "Tags of resources"
  default     = {}
}
