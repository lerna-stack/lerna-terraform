variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "private_ip" {
  description = "Private IP"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "ami" {
  description = "AMI"
  type        = string
}

variable "keypair_key_name" {
  description = "Key name of AWS KeyPair"
}

variable "ssh_user" {
  description = "SSH user name"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private key"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "nfs_export_path" {
  description = "Path to be exported by nfs"
  type        = string
  default     = "/var/share/nfs"
  validation {
    condition     = length(regexall("\\s+", var.nfs_export_path)) == 0
    error_message = "The nfs_export_path must not contain a white space."
  }
}
