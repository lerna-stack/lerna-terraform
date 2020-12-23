resource "aws_instance" "cassandra" {

  count         = length(var.cassandra_private_ips)
  subnet_id     = var.aws_vpc_subnet_id
  instance_type = var.cassandra_instance_type
  ami           = var.aws_ami
  key_name      = aws_key_pair.deployer.key_name
  private_ip    = var.cassandra_private_ips[count.index]

  source_dest_check = false

  vpc_security_group_ids = [
    var.aws_vpc_security_group_id,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.cassandra_volume_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-cassandra-${count.index}"
  }
}

resource "null_resource" "setup_for_cassandra" {
  depends_on = [null_resource.common_settings]
  count      = length(aws_instance.cassandra)

  triggers = {
    instance_cassandra = aws_instance.cassandra.*.id[count.index]
  }

  connection {
    host        = aws_instance.cassandra.*.private_ip[count.index]
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

    : Append hosts
    # EC2 インスタンス上に Cassandra クラスタを構成する〜 java.net.MalformedURLException の対処 〜
    # http://inokara.hateblo.jp/entry/2014/03/04/003032
    host_entry="127.0.0.1 $(hostname)"
    if ! grep --line-regexp --fixed-strings "$host_entry" /etc/hosts > /dev/null
    then
      echo "$host_entry" | sudo tee -a /etc/hosts
    fi
    EOC
    ]
  }
}
