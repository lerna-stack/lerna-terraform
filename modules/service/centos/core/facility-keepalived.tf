resource "null_resource" "keepalived" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.keepalived_ssh_hosts)

  triggers = {
    keepalived_rpm = filemd5(var.keepalived_rpm_path)
  }

  provisioner "file" {
    source      = var.keepalived_rpm_path
    destination = "/tmp/keepalived.rpm"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Add keepalived_script user
      # 警告対策：WARNING - default user 'keepalived_script' for script execution does not exist - please create.
      sudo --askpass useradd --shell /sbin/nologin --no-user-group --gid lv1 --groups lv1 keepalived_script || : user keepalived_script already exists

      : Make /var/run/keepalived/
      # Keepalived がランタイムに利用する一時ファイルを配置するディレクトリ
      sudo --askpass install --owner=keepalived_script --group=lv1 --mode=755 --directory /var/run/keepalived/
      # /var/run 配下のディレクトリは再起動時に消失してしまうため、自動で上記ディレクトリが作られるようにする
      # 参考：https://server.etutsplus.com/centos-7-tmpfiles-d-deleted-outdate-files/
      echo 'd /var/run/keepalived 0755 keepalived_script lv1 -' | sudo --askpass tee /usr/lib/tmpfiles.d/keepalived-var.conf

      : Install Keepalived
      sudo --askpass -E yum install -y /tmp/keepalived.rpm --disableexcludes=all
      rm /tmp/keepalived.rpm

      : Enable Keepalived Service
      sudo --askpass systemctl daemon-reload
      sudo --askpass systemctl enable keepalived.service
    EOC
    ]
  }

  connection {
    host        = var.keepalived_ssh_hosts[count.index]
    user        = var.ssh_users[var.keepalived_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.keepalived_ssh_hosts[count.index]]] : null
  }
}

resource "null_resource" "keepalived_config" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.keepalived_ssh_hosts)

  triggers = {
    keepalived_service            = null_resource.keepalived.*.id[count.index]
    keepalived_conf_common        = md5(data.template_file.keepalived_conf_common.*.rendered[count.index])
    keepalived_conf_section       = md5(data.template_file.keepalived_conf_section.*.rendered[count.index])
    keepalived_sysconfig          = md5(data.template_file.keepalived_sysconfig.*.rendered[count.index])
    keepalived_weight_controll    = filemd5("${path.module}/resources/keepalived/weight_controll.sh")
    keepalived_real_server_status = md5(data.template_file.keepalived_real_server_status.rendered)
  }

  provisioner "file" {
    content     = data.template_file.keepalived_sysctl.rendered
    destination = "/tmp/99-keepalived.conf"
  }

  provisioner "file" {
    content     = data.template_file.keepalived_conf_common.*.rendered[count.index]
    destination = "/tmp/keepalived_common.conf"
  }

  provisioner "file" {
    content     = data.template_file.keepalived_conf_section.*.rendered[count.index]
    destination = "/tmp/keepalived_section_${local.section_id}.conf"
  }

  provisioner "file" {
    content     = data.template_file.keepalived_sysconfig.*.rendered[count.index]
    destination = "/tmp/keepalived.sysconfig"
  }

  provisioner "file" {
    source      = "${path.module}/resources/keepalived/weight_controll.sh"
    destination = "/tmp/weight_controll.sh"
  }

  provisioner "file" {
    content     = data.template_file.keepalived_real_server_status.rendered
    destination = "/tmp/keepalived.real_server_status"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Apply system parameters for Keepalived
      sudo --askpass install --owner=root --mode=0644 /tmp/99-keepalived.conf /etc/sysctl.d/
      sudo --askpass sysctl --load=/etc/sysctl.d/99-keepalived.conf
      rm /tmp/99-keepalived.conf

      : Apply Keepalived config
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/keepalived_common.conf /etc/keepalived/
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/keepalived_section_${local.section_id}.conf /etc/keepalived/
      cat /etc/keepalived/keepalived_common.conf /etc/keepalived/keepalived_section_*.conf > /tmp/keepalived.conf
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/keepalived.conf /etc/keepalived/
      rm /tmp/keepalived.conf
      rm /tmp/keepalived_*.conf

      : Apply Keepalived sysconfig
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/keepalived.sysconfig /etc/sysconfig/keepalived
      rm /tmp/keepalived.sysconfig

      : Apply Keepalived weight controll script
      sudo --askpass install --owner=keepalived_script --group=lv4 --mode=0755 --directory /etc/keepalived/real_servers
      %{for real_server_host in var.haproxy_cluster_hosts[var.active_tenants[0]]}
      sudo --askpass install --owner=keepalived_script --group=lv4 --mode=0664 /tmp/keepalived.real_server_status /etc/keepalived/real_servers/${real_server_host}.status
      %{endfor}
      rm /tmp/keepalived.real_server_status
      sudo --askpass install --owner=keepalived_script --group=lv4 --mode=0764 /tmp/weight_controll.sh /etc/keepalived/weight_controll.sh
      rm /tmp/weight_controll.sh


    EOC
    ]
  }

  connection {
    host        = var.keepalived_ssh_hosts[count.index]
    user        = var.ssh_users[var.keepalived_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.keepalived_ssh_hosts[count.index]]] : null
  }
}

data "template_file" "keepalived_sysctl" {
  template = <<-EOF
  # Keepalived でバックエンドにリクエストをルーティングための設定
  net.ipv4.ip_forward = 1
  EOF
}

data "template_file" "keepalived_conf_common" {
  count = length(var.keepalived_cluster_hosts)

  template = <<-EOF
  ! Configuration File for keepalived

  global_defs {
    vrrp_version 3
    enable_script_security
    script_user keepalived_script
    lvs_sync_daemon ${var.keepalived_lvs_sync_daemon_interface} VI_1
  }

  EOF
}

data "template_file" "keepalived_conf_section" {
  count = length(var.keepalived_cluster_hosts)

  template = <<-EOF
  %{for tenant in var.active_tenants}
  vrrp_script check_lvs_${local.section_id}_${tenant} {
    script "/usr/bin/test -e /var/run/keepalived/keepalived_${local.section_id}_${tenant}.lvs_healthy"
    interval 1
    fall 1
    rise 1
  }

  vrrp_instance VI_${local.section_id}_${tenant} {
    priority 100
    state BACKUP
    interface ${var.keepalived_virtual_ip_interface}      # interface to monitor
    virtual_router_id ${var.keepalived_virtual_router_ids[tenant]} # Assign one ID for this route
    virtual_ipaddress {
      ${var.keepalived_virtual_ips[tenant]}
    }
    unicast_src_ip ${var.keepalived_cluster_hosts[count.index]}
    unicast_peer {
      ${indent(4, join("\n", var.keepalived_cluster_hosts))}
    }
    # 新たなインスタンスが起動したとき、既存の Master よりも priority が高ければそのインスタンスは Master に昇格し、
    # 元の Master は Backup に降格する（デフォルトの振る舞い）
    # Backup に降格する際にダウンタイムが発生するため、既存の Master よりも priority が高くても Master に昇格しないようにする。
    nopreempt
    advert_int 0.4 # seconds
    track_script {
      check_lvs_${local.section_id}_${tenant}
    }
    garp_master_repeat  1
    garp_master_refresh 3 # seconds
  }
  %{endfor}
  ${join("\n", data.template_file.keepalived_virtual_server_conf_section.*.rendered)}
  EOF
}

data "template_file" "keepalived_virtual_server_conf_section" {
  count = length(var.active_tenants)

  template = <<-EOF
  virtual_server ${var.keepalived_virtual_ips[var.active_tenants[count.index]]} 443 {
    lvs_sched rr
    lvs_method TUN

    protocol TCP

    # 初期値をdownにすることで、quorum_upのスクリプトが実行されるようにする
    alpha
    quorum 1
    quorum_up   "/bin/touch /var/run/keepalived/keepalived_${local.section_id}_${var.active_tenants[count.index]}.lvs_healthy"
    quorum_down "/bin/rm    /var/run/keepalived/keepalived_${local.section_id}_${var.active_tenants[count.index]}.lvs_healthy"

    sorry_server ${var.app_cluster_hosts[0]} 1443
    sorry_server_lvs_method TUN

    # バックエンドのヘルスチェック間隔
    # 通常時・ダウン時: delay_loop (seconds)
    # 障害発生中（正常→ダウン移行判定中）: delay_before_retry (seconds)
    #  ⇒ https://github.com/acassen/keepalived/blob/v1.3.5/keepalived/check/check_http.c#L246-L336
    # ※ delay_before_retry は real_servers の中で設定
    delay_loop 0.5 # seconds

    # real server を切り離す際、既にある接続を中断しないようにするため
    inhibit_on_failure

    ${indent(2, data.template_file.keepalived_real_server_conf.*.rendered[count.index])}
  }
  EOF
}

data "template_file" "keepalived_real_server_conf" {
  count = length(var.active_tenants)

  template = <<-EOF
  %{for real_ip in var.haproxy_cluster_hosts[var.active_tenants[count.index]]}
  real_server ${real_ip} 443 {
    lvs_method TUN
    weight 1
    HTTP_GET {
      connect_port 80
      url {
        path        ${var.app_health_check_path}
        status_code 200
      }
      connect_timeout 0.2 #sec

      retry 3 # number of retries before fail.
      delay_before_retry 0.5 # seconds
    }
    MISC_CHECK {
       misc_path "/etc/keepalived/weight_controll.sh ${var.haproxy_cluster_hosts[var.active_tenants[0]][index(var.haproxy_cluster_hosts[var.active_tenants[count.index]], real_ip)]}"
       delay_loop 10
    }
  }
  %{endfor}
EOF
}

data "template_file" "keepalived_sysconfig" {
  count = length(var.app_cluster_hosts)

  template = <<-EOF
  # Options for keepalived. See `keepalived --help' output and keepalived(8) and
  # keepalived.conf(5) man pages for a list of all options. Here are the most
  # common ones :
  #
  # --vrrp               -P    Only run with VRRP subsystem.
  # --check              -C    Only run with Health-checker subsystem.
  # --dont-release-vrrp  -V    Dont remove VRRP VIPs & VROUTEs on daemon stop.
  # --dont-release-ipvs  -I    Dont remove IPVS topology on daemon stop.
  # --dump-conf          -d    Dump the configuration data.
  # --log-detail         -D    Detailed log messages.
  # --log-facility       -S    0-7 Set local syslog facility (default=LOG_DAEMON)
  #

  KEEPALIVED_OPTIONS="-D --log-facility=0"
  EOF
}

data "template_file" "keepalived_real_server_status" {
  template = <<-EOF
  # 指定できるステータス:
  # - active: サーバーを有効化し、リクエスト転送の対象にします
  # - inactive: サーバーを無効化し、リクエスト転送の対象外にします
  active
  EOF
}

resource "null_resource" "keepalived_tools" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.keepalived_ssh_hosts)

  triggers = {
    keepalived_ips = join(",", var.keepalived_cluster_hosts)
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Keepalived の運用に必要なツールをインストール（インターネット接続が必要）
      sudo -E --askpass yum install -y ipvsadm
    EOC
    ]
  }

  connection {
    host        = var.keepalived_ssh_hosts[count.index]
    user        = var.ssh_users[var.keepalived_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.keepalived_ssh_hosts[count.index]]] : null
  }
}
