resource "aws_instance" "app" {

  count         = length(var.app_private_ips)
  subnet_id     = var.aws_vpc_subnet_id
  instance_type = var.app_instance_type
  ami           = var.aws_ami
  key_name      = aws_key_pair.deployer.key_name
  private_ip    = var.app_private_ips[count.index]

  source_dest_check = false

  vpc_security_group_ids = [
    var.aws_vpc_security_group_id,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.app_volume_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-app-${count.index}"
  }
}

resource "null_resource" "setup_for_app" {
  depends_on = [null_resource.common_settings]
  count      = length(aws_instance.app)

  triggers = {
    instance_app = aws_instance.app.*.id[count.index]
  }

  connection {
    host        = aws_instance.app.*.private_ip[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    set -xe

    : update packages
    sudo -E yum update -y
    : install JDK
    sudo -E yum install -y java-1.8.0-openjdk-devel
    EOC
    ]
  }
}
