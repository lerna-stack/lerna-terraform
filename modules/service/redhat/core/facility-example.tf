resource "null_resource" "hello_world" {
  count = length(var.app_ssh_hosts)

  provisioner "remote-exec" {
    inline = [<<EOC
      # /etc/profile を読み込み、実行オプションを指定
      # Terraform の remote-exec 経由では bash のログインセッションが有効にならないため、
      # /etc/profile が読まれず、環境変数などの設定が効かないため /etc/profile を最初に読んで設定を有効にする。
      # sudo --askpass を利用するため、SUDO_ASKPASS 環境変数を設定
      # 実行オプションの意味：
      # e: Terraform の inline は途中でコマンドが失敗しても継続して実行してしまうため
      # x: どこまで処理が進んだか確認しやすくするため
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      # 実行オプション x が有効になっている場合は echo よりも : を使ったほうがログが見やすい
      : Print hello world
      echo 'hello world'

      # 特権が必要なコマンドは sudo --askpass を使う
      # sudo --askpass HOGE curl -sS http://example.com/ | grep '<title>'
    EOC
    ]
  }

  connection {
    host        = var.app_ssh_hosts[count.index]
    user        = var.ssh_users[var.app_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.app_ssh_hosts[count.index]]] : null
  }
}
