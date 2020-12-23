resource "aws_instance" "mariadb" {

  count         = length(var.mariadb_private_ips)
  subnet_id     = var.aws_vpc_subnet_id
  instance_type = var.mariadb_instance_type
  ami           = var.aws_ami
  key_name      = aws_key_pair.deployer.key_name
  private_ip    = var.mariadb_private_ips[count.index]

  source_dest_check = false

  vpc_security_group_ids = [
    var.aws_vpc_security_group_id,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.mariadb_volume_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-mariadb-${count.index}"
  }
}

resource "null_resource" "setup_for_mariadb" {
  depends_on = [null_resource.common_settings]
  count      = length(aws_instance.mariadb)

  triggers = {
    instance_haproxy = aws_instance.mariadb.*.id[count.index]
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      set -xe

      : update packages
      sudo -E yum update -y

    EOC
    ]
  }

  connection {
    host        = aws_instance.mariadb.*.private_ip[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}
