resource "aws_instance" "keepalived" {

  count         = length(var.keepalived_private_ips)
  subnet_id     = var.aws_vpc_subnet_id
  instance_type = var.keepalived_instance_type
  ami           = var.aws_ami
  key_name      = aws_key_pair.deployer.key_name
  private_ip    = var.keepalived_private_ips[count.index]

  source_dest_check = false

  iam_instance_profile = aws_iam_instance_profile.keepalived_profile.name

  vpc_security_group_ids = [
    var.aws_vpc_security_group_id,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.keepalived_volume_size_gb
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-keepalived-${count.index}"
  }
}

data "template_file" "aws_vpc_garp_support_service" {
  template = <<-EOF
  [Unit]
  Description = Replace virtual ip route in Amazon VPC route-table by Gratuitous ARP

  [Service]
  ExecStart   = /usr/local/bin/aws-vpc-garp-support.sh
  Restart     = always
  RestartSec  = 3
  Type        = simple
  Environment = NETWORK_INTERFACE=${var.keepalived_vrrp_network_interface}
  Environment = ROUTE_TABLE_ID=${var.aws_vpc_route_table_id_for_virtual_ips}
  Environment = "VIRTUAL_IPS=${join(" ", var.keepalived_virtual_ips)}"
  %{if var.http_proxy_host != ""}
  Environment = http_proxy=http://${var.http_proxy_host}:${var.http_proxy_port}
  Environment = https_proxy=http://${var.http_proxy_host}:${var.http_proxy_port}
  %{endif}
  Environment = no_proxy=169.254.169.254

  [Install]
  WantedBy = multi-user.target
  EOF
}

resource "null_resource" "setup_for_keepalived" {
  depends_on = [null_resource.common_settings]
  count      = length(aws_instance.keepalived)

  triggers = {
    aws_vpc_garp_support_script  = filemd5("${path.module}/resources/aws-vpc-garp-support/aws-vpc-garp-support.sh")
    aws_vpc_garp_support_service = md5(data.template_file.aws_vpc_garp_support_service.rendered)
    aws_instance                 = aws_instance.keepalived.*.id[count.index]
    keepalived_rsyslog           = md5(data.template_file.keepalived_rsyslog.rendered)
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /tmp/aws-vpc-garp-support"]
  }

  provisioner "file" {
    content     = data.template_file.aws_vpc_garp_support_service.rendered
    destination = "/tmp/aws-vpc-garp-support/aws-vpc-garp-support.service"
  }

  provisioner "file" {
    source      = "${path.module}/resources/aws-vpc-garp-support"
    destination = "/tmp"
  }

  provisioner "file" {
    content     = data.template_file.keepalived_rsyslog.rendered
    destination = "/tmp/keepalived-rsyslog.conf"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      set -xe

      : update packages
      sudo -E yum update -y

      sudo -E yum install -y tcpdump

      if ! which aws # aws コマンドがない場合
      then
        : Install aws cli
        # https://docs.aws.amazon.com/cli/latest/userguide/install-linux.html
        sudo -E yum install -y unzip python38
        sudo alternatives --set python /usr/bin/python3  # 'python' コマンドを python3 に向ける
        curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
        unzip -o awscli-bundle.zip
        sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
      fi

      sudo install --owner=root --group=root --mode=0755 /tmp/aws-vpc-garp-support/aws-vpc-garp-support.sh      /usr/local/bin/aws-vpc-garp-support.sh
      sudo install --owner=root --group=root --mode=0644 /tmp/aws-vpc-garp-support/aws-vpc-garp-support.service /etc/systemd/system/aws-vpc-garp-support.service
      sudo systemctl daemon-reload
      sudo systemctl enable  aws-vpc-garp-support
      sudo systemctl restart aws-vpc-garp-support

      : Place rsyslog settings
      sudo install --owner=root --group=root --mode=0644 /tmp/keepalived-rsyslog.conf /etc/rsyslog.d/keepalived.conf
      rm /tmp/keepalived-rsyslog.conf
      sudo mkdir -p /var/log/keepalived
    EOC
    ]
  }

  connection {
    host        = aws_instance.keepalived.*.private_ip[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}

resource "aws_iam_instance_profile" "keepalived_profile" {
  name = "${var.name_prefix}-keepalived_profile"
  role = var.aws_keepalived_instance_role_name
}

data "template_file" "keepalived_rsyslog" {
  template = <<-EOF
  #keepalived log
  local0.*                                                /var/log/keepalived/keepalived.log
  #keepalived emerge log
  local0.emerg                                            /var/log/keepalived/keepalived_error.log
  EOF
}
