#
# lerna-sample-payment-app が依存する 外部サービスモック
#
# lerna-sample-payment-app => mock-server
#
resource "null_resource" "mock-server" {
  count = length(module.lerna_stack_platform_aws_ec2.app_instance_ips)

  triggers = {
    docker_compose  = md5(data.template_file.docker_compose.rendered)
    http_proxy_conf = md5(data.template_file.http_proxy_conf.rendered)
    mock_server     = data.archive_file.mock-server.output_md5
  }

  connection {
    host        = module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]
    user        = module.lerna_stack_platform_aws_ec2.ssh_user
    private_key = file(module.lerna_stack_platform_aws_ec2.ssh_private_key)
  }

  provisioner "file" {
    content     = data.template_file.docker_compose.rendered
    destination = "/tmp/docker-compose.yml"
  }

  provisioner "file" {
    content     = data.template_file.http_proxy_conf.rendered
    destination = "/tmp/http-proxy.conf"
  }

  provisioner "file" {
    source      = "${path.module}/resources/mock-server.zip"
    destination = "/tmp/mock-server.zip"
  }

  provisioner "remote-exec" {
    inline = [<<-EOC

    set -Cex

    sudo -E yum update -y
    sudo -E yum install -y unzip wget

    # Install Docker Engine
    # https://docs.docker.com/engine/install/centos/#install-using-the-repository
    sudo -E yum install -y yum-utils
    sudo -E yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo -E yum install -y docker-ce docker-ce-cli containerd.io

    # Configure HTTP Proxy used by Docker
    # https://docs.docker.com/config/daemon/systemd/#httphttps-proxy
    sudo mkdir -p /etc/systemd/system/docker.service.d
    cat /tmp/http-proxy.conf | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf

    # Install Docker Compose
    # https://docs.docker.com/compose/install/#install-compose-on-linux-systems
    curl -L https://github.com/docker/compose/releases/download/1.28.5/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
    sudo chmod +x /usr/local/bin/docker-compose

    sudo gpasswd -a ${var.ssh_user} docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo systemctl enable docker

    cat /tmp/docker-compose.yml | sudo tee ./docker-compose.yml

    # Cleanup
    rm -f /tmp/docker-compose.yml
    rm -f /tmp/http-proxy.conf

    EOC
    ]
  }

  provisioner "remote-exec" {
    inline = [<<-EOC

    set -Cex

    # Replace ~/mock-server
    mv /tmp/mock-server.zip ./mock-server.zip
    rm -rf ./mock-server
    unzip -d ./mock-server ./mock-server.zip
    rm -f ./mock-server.zip

    # Rebuild docker images & Restart docker containers
    docker-compose up -d --build --force-recreate

    EOC
    ]
  }

}

data "template_file" "docker_compose" {
  template = <<-EOF

version: '3'

services:
  mock:
    build:
      context: ~/mock-server
      args:
        http_proxy:
        https_proxy:
    restart: always
    ports:
      - 8083:3000

  EOF
}

data "template_file" "http_proxy_conf" {
  template = <<-EOF

# See
# https://docs.docker.jp/config/daemon/systemd.html#http-https

[Service]
${var.http_proxy_host != ""
  ? "Environment=\"HTTP_PROXY=http://${var.http_proxy_host}:${var.http_proxy_port}\""
  : ""
  }
${var.http_proxy_host != ""
  ? "Environment=\"HTTPS_PROXY=http://${var.http_proxy_host}:${var.http_proxy_port}\""
  : ""
}
Environment="NO_PROXY=localhost"

  EOF
}

data "archive_file" "mock-server" {
  type        = "zip"
  source_dir  = "${path.module}/resources/mock-server"
  output_path = "${path.module}/resources/mock-server.zip"
}
