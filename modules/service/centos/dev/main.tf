locals {
  # HAProxy サーバーにインストールする SSL 証明書のパス。SSL 通信で利用
  haproxy_crt_file_path = "/usr/local/certs/lerna.test.pem"
}

resource "null_resource" "haproxy_ssl_cert" {
  for_each = toset(var.haproxy_ssh_hosts)

  triggers = {
    crt_file = filemd5("${path.module}/resources/haproxy/ssl/lerna.test.pem")
  }

  provisioner "file" {
    source      = "${path.module}/resources/haproxy/ssl/lerna.test.pem"
    destination = "/tmp/haproxy-ssl.lerna.test.pem"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      set -xe

      : Place crt file
      sudo install --owner=root --group=root --mode=0644 -D /tmp/haproxy-ssl.lerna.test.pem '${local.haproxy_crt_file_path}'
    EOC
    ]
  }

  connection {
    host        = each.value
    user        = var.ssh_users[each.value]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[each.value]] : null
  }
}
