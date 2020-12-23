#
# 以下のネットワーク経路の疎通確認用
#
# gatling → keepalived → haproxy → app
#
resource "null_resource" "fake_app" {
  count = length(module.lerna_stack_platform_aws_ec2.app_instance_ips)

  triggers = {
    fake_app_sh      = filemd5("${path.module}/fake-app.sh")
    fake_app_service = md5(data.template_file.fake_app_service.rendered)
  }

  provisioner "file" {
    source      = "${path.module}/fake-app.sh"
    destination = "/tmp/fake-app.sh"
  }

  provisioner "file" {
    content     = data.template_file.fake_app_service.rendered
    destination = "/tmp/fake-app.service"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      set -ex

      sudo -E yum install -y socat

      sudo --askpass install --owner=root --group=lv4 --mode=0764 /tmp/fake-app.sh /usr/local/bin/fake-app.sh
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/fake-app.service /usr/lib/systemd/system/fake-app.service

      rm /tmp/fake-app.sh
      rm /tmp/fake-app.service
    EOC
    ]
  }

  connection {
    host        = module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]
    user        = module.lerna_stack_platform_aws_ec2.ssh_user
    private_key = file(module.lerna_stack_platform_aws_ec2.ssh_private_key)
  }
}

data "template_file" "fake_app_service" {
  template = <<-EOF
  [Unit]
  Description = fake application
  After = network.target

  [Service]
  Type = simple
  ExecStart = /usr/local/bin/fake-app.sh
  Restart = always
  RestartSec = 3

  [Install]
  WantedBy = multi-user.target
EOF
}
