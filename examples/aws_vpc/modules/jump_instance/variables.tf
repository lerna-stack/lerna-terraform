variable "ami" {
  type        = string
  description = "AMI ID"
  # example = "ami-00f045aed21a55240"
}
variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "t2.micro"
}
variable "ssh_public_key" {
  type        = string
  description = "SSH public key to be installed to the instance"
  # example = "./assets/id_rsa.pub"
}
variable "subnet_id" {
  type        = string
  description = "Subnet ID to be attached to the instance"
  # example = "subnet-0123456789abcdef0"
}
variable "tags" {
  type        = map(string)
  description = "Tags of resources"
  default     = {}
}
