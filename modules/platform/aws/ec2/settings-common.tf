# 共通設定の依存をまとめるためのリソース
resource "null_resource" "common_settings" {
  depends_on = [
    null_resource.common_http_proxy_settings,
    null_resource.common_role_groups,
    null_resource.common_chrony,
    null_resource.common_dnf_tuning,
  ]
}

data "template_file" "http_proxy_profile" {
  template = <<-EOF
  export http_proxy=http://${var.http_proxy_host}:${var.http_proxy_port}
  export https_proxy=http://${var.http_proxy_host}:${var.http_proxy_port}
  export no_proxy=localhost,127.0.0.1,${join(",", local.instance_private_ips)}
  EOF
}

resource "null_resource" "common_http_proxy_settings" {
  count = length(local.instance_private_ips)

  triggers = {
    http_proxy = md5(data.template_file.http_proxy_profile.rendered)
  }

  provisioner "file" {
    content     = data.template_file.http_proxy_profile.rendered
    destination = "/tmp/http_proxy.sh"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      set -xe

      sudo install --owner=root --group=root --mode=0644 /tmp/http_proxy.sh /etc/profile.d/http_proxy.sh
      # プロキシが不要な場合は削除する
      ${var.http_proxy_host == "" ? "sudo rm /etc/profile.d/http_proxy.sh" : ""}
      rm /tmp/http_proxy.sh
    EOC
    ]
  }

  connection {
    host        = local.instance_private_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}

resource "null_resource" "common_role_groups" {
  count = length(local.instance_private_ips)

  triggers = {
    instance_private_ips = join(",", local.instance_private_ips)
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    set -xe

    : Add role groups
    sudo /usr/sbin/groupadd --force lv1 # 制限付き参照ロール
    sudo /usr/sbin/groupadd --force lv2 # 制限付き変更ロール
    sudo /usr/sbin/groupadd --force lv3 # 参照ロール
    sudo /usr/sbin/groupadd --force lv4 # 変更ロール
    sudo /usr/sbin/groupadd --force lv5 # 特権ロール（sudo 実行可）

    : Append groups to user
    # ssh ユーザーは sudo が実行可能なため lv5
    sudo usermod --append --groups lv4,lv5 ${var.ssh_user}
    EOC
    ]
  }

  connection {
    host        = local.instance_private_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}

resource "null_resource" "common_chrony" {
  depends_on = [null_resource.common_http_proxy_settings, null_resource.common_dnf_tuning]
  count      = length(local.instance_private_ips)

  triggers = {
    instance_private_ip = local.instance_private_ips[count.index]
    chrony_conf         = filemd5("${path.module}/resources/chrony/chrony.conf")
  }

  provisioner "file" {
    source      = "${path.module}/resources/chrony/chrony.conf"
    destination = "/tmp/chrony.conf"
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    set -xe

    sudo -E yum -y install chrony

    : Place chrony.conf
    sudo install --owner=root --mode=0644 /tmp/chrony.conf /etc/
    rm /tmp/chrony.conf

    sudo systemctl enable chronyd
    sudo systemctl restart chronyd
    EOC
    ]
  }

  connection {
    host        = local.instance_private_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}

resource "null_resource" "common_dnf_tuning" {
  depends_on = [null_resource.common_http_proxy_settings]
  count      = length(local.instance_private_ips)

  triggers = {
    instance_private_ip = local.instance_private_ips[count.index]
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    set -xe

    # パッケージインストールがとても遅くなる場合があるので設定
    # https://www.tekfik.com/kb/linux/fedora-rhel-centos-dnf-extremely-slow
    # https://www.reddit.com/r/Fedora/comments/bc9pyz/why_is_dnf_so_excruciatingly_slow/
    sudo sed --regexp-extended --in-place \
      -e '/^ip_resolve=/d'              -e '$a ip_resolve=4' \
      -e '/^fastestmirror=/d'           -e '$a fastestmirror=true' \
      -e '/^max_parallel_downloads=/d'  -e '$a max_parallel_downloads=10' \
      /etc/dnf/dnf.conf

    sudo dnf clean all

    EOC
    ]
  }

  connection {
    host        = local.instance_private_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}
