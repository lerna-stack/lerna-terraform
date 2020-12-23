resource "aws_instance" "gatling" {

  count         = length(var.gatling_private_ips)
  subnet_id     = var.aws_vpc_subnet_id
  instance_type = var.gatling_instance_type
  ami           = var.aws_ami
  key_name      = aws_key_pair.deployer.key_name
  private_ip    = var.gatling_private_ips[count.index]

  source_dest_check = false

  vpc_security_group_ids = [
    var.aws_vpc_security_group_id,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.gatling_volume_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-gatling-${count.index}"
  }
}

resource "null_resource" "setup_for_gatling" {
  depends_on = [null_resource.common_settings]
  count      = length(aws_instance.gatling)

  triggers = {
    instance_gatling = aws_instance.gatling.*.id[count.index]
  }

  connection {
    host        = aws_instance.gatling.*.private_ip[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    set -xe
    : update packages
    sudo -E yum update -y
    : install jdk
    sudo -E yum install -y java-1.8.0-openjdk-devel git
    : install sbt
    curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
    sudo -E yum install -y sbt
    EOC
    ]
  }
}
