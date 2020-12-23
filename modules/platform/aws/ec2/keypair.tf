resource "aws_key_pair" "deployer" {
  key_name_prefix = "${var.name_prefix}-"
  public_key      = file(var.ssh_public_key)
}
