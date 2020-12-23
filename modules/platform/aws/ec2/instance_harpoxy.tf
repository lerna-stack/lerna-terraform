resource "aws_instance" "haproxy" {

  count         = length(var.haproxy_private_ips)
  subnet_id     = var.aws_vpc_subnet_id
  instance_type = var.haproxy_instance_type
  ami           = var.aws_ami
  key_name      = aws_key_pair.deployer.key_name
  private_ip    = var.haproxy_private_ips[count.index]

  source_dest_check = false

  vpc_security_group_ids = [
    var.aws_vpc_security_group_id,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.haproxy_volume_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-haproxy-${count.index}"
  }
}


resource "null_resource" "setup_for_haproxy" {
  depends_on = [null_resource.common_settings]
  count      = length(aws_instance.haproxy)

  triggers = {
    instance_haproxy = aws_instance.haproxy.*.id[count.index]
    haproxy_rsyslog  = md5(data.template_file.haproxy_rsyslog.rendered)
  }

  provisioner "file" {
    content     = data.template_file.haproxy_rsyslog.rendered
    destination = "/tmp/haproxy-rsyslog.conf"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      set -xe

      : update packages
      sudo -E yum update -y

      : Place rsyslog settings
      sudo install --owner=root --group=root --mode=0644 /tmp/haproxy-rsyslog.conf /etc/rsyslog.d/haproxy.conf
      rm /tmp/haproxy-rsyslog.conf
      sudo mkdir -p /var/log/haproxy
    EOC
    ]
  }

  connection {
    host        = aws_instance.haproxy.*.private_ip[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}

data "template_file" "haproxy_rsyslog" {
  template = <<-EOF
  #haproxy log
  local0.*                                                /var/log/haproxy/haproxy.log
  #haproxy emerge log
  local0.emerg                                            /var/log/haproxy/haproxy_error.log
  EOF
}
