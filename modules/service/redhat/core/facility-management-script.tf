
locals {
  management_script_global_hosts = distinct(concat(var.keepalived_ssh_hosts, var.haproxy_ssh_hosts, var.cassandra_ssh_hosts, var.app_ssh_hosts))
}

resource "null_resource" "management_script_global" {

  depends_on = [null_resource.sudo_askpass]
  count      = length(local.management_script_global_hosts)

  triggers = {
    hosts                    = join(",", local.management_script_global_hosts)
    management_script_global = data.archive_file.management_script_global.output_md5
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    mkdir -p /tmp/management_script_global
    EOC
    ]
  }

  provisioner "file" {
    source      = "${path.module}/resources/management-script/global/"
    destination = "/tmp/management_script_global"
  }

  # Setup cassandra
  provisioner "remote-exec" {
    inline = [<<-EOC
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    : create directory
    sudo --askpass install --owner=root --group=root --mode=775 --directory /opt/management
    sudo --askpass install --owner=root --group=root --mode=775 --directory /opt/management/bin

    : install scripts
    sudo --askpass install --owner=root --group=root --mode=775 /tmp/management_script_global/* /opt/management/bin/

    : cleanup
    rm -rf /tmp/management_script_global
    EOC
    ]
  }

  connection {
    host        = local.management_script_global_hosts[count.index]
    user        = var.ssh_users[local.management_script_global_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[local.management_script_global_hosts[count.index]]] : null
  }
}

/**
 * management script の変更を検知するための workaround
 * Can Terraform watch a directory for changes? - Stack Overflow
 * https://stackoverflow.com/questions/51138667/can-terraform-watch-a-directory-for-changes#answer-54815973
 */
data "archive_file" "management_script_global" {
  type        = "zip"
  source_dir  = "${path.module}/resources/management-script/global"
  output_path = "${path.module}/resources/management-script/global.zip"
}

/**
 * 特権が必要な操作は sudo で実行する。sudo はパスワード認証が必要なケースがあるが、
 * Terraform は sudo のパスワード確認を解決する機能を有していない。
 *
 * パスワード確認ができないと設定ファイルのインストールなどができないため、
 * SUDO_ASKPASS を用いてパスワードを sudo コマンド側で自動解決させる。
 */
resource "null_resource" "sudo_askpass" {
  count = var.enable_sudo_askpass ? length(local.management_script_global_hosts) : 0

  triggers = {
    hosts        = join(",", local.management_script_global_hosts)
    ssh_user     = var.ssh_users[local.management_script_global_hosts[count.index]]
    sudo_askpass = md5(data.template_file.sudo_askpass.*.rendered[count.index])
  }

  provisioner "remote-exec" {
    inline = [<<-EOF
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    install --mode=0700 --directory ~/.sudo
    cd ~/.sudo
    umask 0077 # .sudo ディレクトリに作成されるファイルはデフォルトで他人がアクセスできなくなる
    EOF
    ]
  }

  provisioner "file" {
    content     = data.template_file.sudo_askpass.*.rendered[count.index]
    destination = local.sudo_askpass_path
  }

  provisioner "remote-exec" {
    inline = [<<-EOF
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    chmod 700 ~/.sudo/askpass.sh
    EOF
    ]
  }

  connection {
    host        = local.management_script_global_hosts[count.index]
    user        = var.ssh_users[local.management_script_global_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[local.management_script_global_hosts[count.index]]] : null
  }
}

data "template_file" "sudo_askpass" {
  count = var.enable_sudo_askpass ? length(local.management_script_global_hosts) : 0

  template = <<-EOF
  #!/bin/bash
  echo '${var.ssh_passwords[var.ssh_users[local.management_script_global_hosts[count.index]]]}'
  EOF
}
