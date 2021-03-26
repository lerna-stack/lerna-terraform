#
# lerna-sample-payment-app が依存する 外部サービスモック
#
# lerna-sample-payment-app => mock-server
#
resource "null_resource" "setup_for_mock_server" {
  count = length(module.lerna_stack_platform_aws_ec2.app_instance_ips)

  # Files of a mock-server is served by an Application RPM package
  depends_on = [module.lerna_stack_service_redhat_core]

  triggers = {
    app_rpm             = filemd5(var.app_rpm_path)
    mock_server_service = md5(data.template_file.mock_server_service.rendered)
  }

  connection {
    host        = module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]
    user        = module.lerna_stack_platform_aws_ec2.ssh_user
    private_key = file(module.lerna_stack_platform_aws_ec2.ssh_private_key)
  }

  provisioner "file" {
    content     = data.template_file.mock_server_service.rendered
    destination = "/tmp/mock-server.service"
  }

  provisioner "remote-exec" {
    inline = [<<-EOC

    set -Cex

    sudo -E yum update -y
    sudo -E yum install -y curl

    # Install Node.js v12.x
    # https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions-1
    curl -fsSL https://rpm.nodesource.com/setup_12.x | sudo bash -
    sudo -E yum install -y nodejs

    sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/mock-server.service /usr/lib/systemd/system/mock-server.service
    sudo systemctl restart mock-server
    sudo systemctl enable mock-server

    rm /tmp/mock-server.service

    EOC
    ]
  }

}

data "template_file" "mock_server_service" {
  template = <<-EOF

[Unit]
Description ="Mock Server for lerna-sample-payment-app"
After = network.target

[Service]
Type = simple
WorkingDirectory = ${local.mock-server-docker-filepath}
ExecStartPre = /usr/bin/npm install
ExecStart = /usr/bin/npm start -- --host '0.0.0.0' --port 8083
ExecStop = /usr/bin/npm stop
Restart = always
RestartSec = 3

[Install]
WantedBy = multi-user.target

EOF
}
