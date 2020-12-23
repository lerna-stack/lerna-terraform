variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
  # example = "AKIAxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
  # example = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "ssh_public_key_filepath" {
  type        = string
  description = "A file path of SSH Public Key"
  # example = "./assets/id_rsa.pub"
}
