resource "null_resource" "haproxy" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.haproxy_ssh_hosts)

  triggers = {
    haproxy_ips              = join(",", flatten(values(var.haproxy_cluster_hosts)))
    haproxy_rpm              = filemd5(var.haproxy_rpm_path)
    haproxy_rpm_name         = basename(var.haproxy_rpm_path)
    haproxy_service_override = md5(data.template_file.haproxy_service_override.rendered)
  }

  provisioner "file" {
    source      = var.haproxy_rpm_path
    destination = "/tmp/haproxy.rpm"
  }

  provisioner "file" {
    content     = data.template_file.haproxy_service_override.rendered
    destination = "/tmp/haproxy.service.override"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Install HAProxy
      sudo --askpass -E yum install -y /tmp/haproxy.rpm --disableexcludes=all # haproxy は yum の自動更新対象外にしているため
      rm /tmp/haproxy.rpm

      : Place Service config file
      sudo --askpass install -D --owner=root --group=lv4 --mode=0664 /tmp/haproxy.service.override /etc/systemd/system/haproxy.service.d/override.conf
      sudo --askpass systemctl daemon-reload
      sudo --askpass systemctl enable haproxy.service
      rm /tmp/haproxy.service.override
    EOC
    ]
  }

  connection {
    host        = var.haproxy_ssh_hosts[count.index]
    user        = var.ssh_users[var.haproxy_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.haproxy_ssh_hosts[count.index]]] : null
  }
}

resource "null_resource" "haproxy_config" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.haproxy_ssh_hosts)

  triggers = {
    haproxy                         = null_resource.haproxy.*.id[count.index]
    haproxy_sysctl                  = md5(data.template_file.haproxy_sysctl.rendered)
    haproxy_config_common           = md5(data.template_file.haproxy_cfg_common.rendered)
    haproxy_config_section          = md5(data.template_file.haproxy_cfg_section.*.rendered[count.index])
    health_check                    = md5(data.template_file.haproxy_errofile_health_check.rendered)
    restriction_mode                = md5(data.template_file.haproxy_errofile_request_restriction_mode.rendered)
    maintenance_mode                = md5(data.template_file.haproxy_errofile_maintenance_mode.rendered)
    haproxy_use_backend_map_section = md5(data.template_file.haproxy_use_backend_map_section.*.rendered[count.index])
  }

  provisioner "file" {
    content     = data.template_file.haproxy_sysctl.rendered
    destination = "/tmp/99-haproxy.conf"
  }

  provisioner "file" {
    content     = data.template_file.haproxy_cfg_common.rendered
    destination = "/tmp/haproxy_common.cfg"
  }

  provisioner "file" {
    content     = data.template_file.haproxy_cfg_section.*.rendered[count.index]
    destination = "/tmp/haproxy_section_${local.section_id}.cfg"
  }

  provisioner "file" {
    // HTTP の仕様に準拠し、改行コードが \r\n でないと Keepalived からのヘルスチェックに失敗するため
    content     = replace(data.template_file.haproxy_errofile_health_check.rendered, "/\r*\n/", "\r\n")
    destination = "/tmp/health_check.http"
  }

  provisioner "file" {
    // HTTP の仕様に準拠し、改行コードが \r\n でないと Keepalived からのヘルスチェックに失敗するため
    content     = replace(data.template_file.haproxy_errofile_request_restriction_mode.rendered, "/\r*\n/", "\r\n")
    destination = "/tmp/request_restriction_mode.http"
  }

  provisioner "file" {
    // HTTP の仕様に準拠し、改行コードが \r\n でないと Keepalived からのヘルスチェックに失敗するため
    content     = replace(data.template_file.haproxy_errofile_maintenance_mode.rendered, "/\r*\n/", "\r\n")
    destination = "/tmp/maintenance_mode.http"
  }

  provisioner "file" {
    content     = data.template_file.haproxy_use_backend_map_section.*.rendered[count.index]
    destination = "/tmp/haproxy_use_backend_section_${local.section_id}.map"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      sudo --askpass install --mode=775 --owner=root --group=lv4 --directory /etc/haproxy/errors/
      sudo --askpass install --mode=775 --owner=root --group=lv4 --directory /var/lib/haproxy
      sudo --askpass install --mode=775 --owner=root --group=lv4 --directory /etc/haproxy/maps/

      : Place sysctl files
      sudo --askpass install --owner=root --mode=0644 /tmp/99-haproxy.conf /etc/sysctl.d/
      : tunl0 のカーネルパラメーターを設定するため、tunl0 を作っておく
      sudo --askpass modprobe ipip
      : Apply system parameters for keepalived backend
      sudo --askpass sysctl --load=/etc/sysctl.d/99-haproxy.conf

      : Place config files
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/haproxy_section_${local.section_id}.cfg /etc/haproxy/
      cat /tmp/haproxy_common.cfg  /etc/haproxy/haproxy_section_*.cfg > /tmp/haproxy.cfg
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/haproxy.cfg /etc/haproxy/
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/health_check.http  /etc/haproxy/errors/
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/maintenance_mode.http  /etc/haproxy/errors/
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/request_restriction_mode.http  /etc/haproxy/errors/

      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/haproxy_use_backend_section_${local.section_id}.map /etc/haproxy/maps/
      cat /etc/haproxy/maps/haproxy_use_backend_section_*.map > /tmp/haproxy_use_backend.map
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/haproxy_use_backend.map /etc/haproxy/maps/

      : clean up
      rm /tmp/99-haproxy.conf
      rm /tmp/haproxy.cfg
      rm /tmp/haproxy_*.cfg
      rm /tmp/health_check.http
      rm /tmp/maintenance_mode.http
      rm /tmp/request_restriction_mode.http
      rm /tmp/haproxy_use_backend.map
      rm /tmp/haproxy_use_backend_section_*.map

    EOC
    ]
  }

  connection {
    host        = var.haproxy_ssh_hosts[count.index]
    user        = var.ssh_users[var.haproxy_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.haproxy_ssh_hosts[count.index]]] : null
  }
}

data "template_file" "haproxy_sysctl" {
  template = <<-EOF
  ################################################
  # TCP 関係のチューニング
  ################################################
  # フェイルオーバー時に Connection Timeout が大量発生するのを回避
  net.ipv4.tcp_max_syn_backlog = 1000
  net.core.somaxconn = 1000
  net.core.netdev_max_backlog = 1000
  ################################################
  # Keepalived から転送されたパケットを処理するための設定
  ################################################
  # tunl0 を経由してパケットを処理するため逆経路フィルタを無効化
  net.ipv4.conf.all.rp_filter = 0
  net.ipv4.conf.tunl0.rp_filter = 0
  # ARP問題対策：https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/7/html/load_balancer_administration/s1-lvs-direct-vsa#s2-lvs-direct-sysctl-VSA
  net.ipv4.conf.tunl0.arp_ignore = 1
  net.ipv4.conf.tunl0.arp_announce = 2
  EOF
}

data "template_file" "haproxy_cfg_common" {
  vars = {
    unique-id-format = "%%{+X}o%f-%H-%lc-%Ts-%ms"
  }

  template = <<-EOF
  global
    daemon
    # 約8GB(7,985MB)メモリの場合のfd max: 813,889
    # Max port数: 65535
    # 1リクエストで 2port(fd)を使う
    # 30,000コネクション = 1,000 TPS * 30s (30秒耐えられる計算)
    maxconn 30000
    log /dev/log local0 info
    # level: userとoperatorは主に参照権限しか無い様なので今回はadminを選択しました。
    # ドキュメント: https://cbonte.github.io/haproxy-dconv/1.9/management.html
    stats socket /var/lib/haproxy/haproxy-cli.sock mode 775 user root group lv4 level admin

  defaults
      mode http
      timeout queue  60000ms
      timeout http-request 180000ms
      timeout connect  200ms
      timeout client 580000ms
      timeout server 575000ms
      log global
      log-format %pid\t%tr\t%ID\t%ci\t%cp\t%f\t%b\t%s\t%si\t%sp\t%sslc\t%sslv\t%HM\t%HV\t%HP\t%HQ\t%ST\t%B\t%Tr\t%Tc\t%Tw\t%TR\t%Ta\t%ac\t%fc\t%bc\t%sc\t%rc\t%sq\t%bq\t%ts\t%[var(txn.tenant_id)]
      unique-id-format $${unique-id-format}
      unique-id-header X-Tracing-Id

  backend health-check
      errorfile 503 /etc/haproxy/errors/health_check.http

  backend maintenance-error
      errorfile 503 /etc/haproxy/errors/maintenance_mode.http

  backend restriction-error
      errorfile 503 /etc/haproxy/errors/request_restriction_mode.http

  EOF
}

data "template_file" "haproxy_cfg_section" {

  count = length(var.haproxy_ssh_hosts)

  template = <<-EOF
  %{for tenant in var.active_tenants}
  # Keepalived からのヘルスチェックを受け付ける
  frontend http-health-check-${var.haproxy_cluster_hosts[tenant][count.index]}
      bind ipv4@${var.haproxy_cluster_hosts[tenant][count.index]}:80
      # ヘルスチェックのときはアクセスログ出力しない
      http-request set-log-level debug if { path_beg /health }
      acl is_active_backend nbsrv(app-${tenant}-${local.section_id}) gt 0
      use_backend health-check if is_active_backend
      default_backend maintenance-error
  %{endfor}

  %{for tenant in var.active_tenants}
  frontend https-${tenant}-${local.section_id}
      bind ipv4@${var.keepalived_virtual_ips[tenant]}:443 ssl crt ${var.haproxy_crt_file_path[tenant]} ${var.haproxy_ca_file_path == "" ? "" : "ca-file ${var.haproxy_ca_file_path}"}
      # ヘルスチェックのときはアクセスログ出力しない
      http-request set-log-level debug if { path_beg /health }
      http-request set-var(txn.tenant_id) str(${tenant})
      http-request set-header X-Tenant-Id %[var(txn.tenant_id)]
      maxconn ${var.haproxy_max_connection[tenant]}
      use_backend %[str(https-${tenant}-${local.section_id}),map(/etc/haproxy/maps/haproxy_use_backend.map,maintenance-error)]
  %{endfor}

  %{for tenant in var.active_tenants}
  backend app-${tenant}-${local.section_id}
      # HAProxy のヘルスチェック用リクエストはデフォルトで Host ヘッダなし
      # Akka HTTP は Host ヘッダなしのリクエストを拒否するため、Host ヘッダを指定する
      option httpchk GET ${var.app_health_check_path} HTTP/1.0\r\nHost:\ ${var.haproxy_cluster_hosts[tenant][count.index]}\r\nX-Tenant-Id:\ ${tenant}
      http-check expect status 200
      stick-table  type string len 100  size 100K  expire 3s  store http_req_rate(1s)
      http-request track-sc0 hdr(X-Tenant-Id)
      http-request deny deny_status 503 if { sc0_http_req_rate gt ${var.haproxy_rate_limit_tps[tenant]} }
      default-server inter 500ms fall 3 rise 2
      errorfile 503 /etc/haproxy/errors/request_restriction_mode.http

      ${indent(4, join("\n", formatlist("server %s %s:%s maxconn %d check port %d", var.app_cluster_hosts, var.app_cluster_hosts, var.app_service_port, var.haproxy_to_app_max_connection[tenant], var.app_health_check_port)))}
  %{endfor}
  EOF
}

data "template_file" "haproxy_service_override" {
  template = <<-EOF
  [Service]
  # HAProxy が自身で自動設定するため、設定不要
  # see: https://cbonte.github.io/haproxy-dconv/1.9/management.html#chapter-5
  #LimitNOFILE=10000
  LimitNPROC=32768
  LimitAS=infinity
  EOF
}

data "template_file" "haproxy_errofile_health_check" {
  template = <<-EOF
  HTTP/1.1 200 OK
  Content-Type: text/plain
  Content-Length: 2

  OK
  EOF
}

data "template_file" "haproxy_use_backend_map_section" {

  count = length(var.app_cluster_hosts)

  template = <<-EOF
  %{for tenant in var.active_tenants}
  https-${tenant}-${local.section_id}   app-${tenant}-${local.section_id}
  %{endfor}
  EOF
}

#流量制限
#Content-Length計算方法
#echo -ne '{"code":"MNN01ZZ1011","message":"現在システムメンテナンス中のためご利用頂けません。"}' | wc --bytes
#もし改行の空行があれば、HTMLで改行は(\r\n)ので、計算された結果は↓改行2個入れるのは正解です。
#echo -ne '{"code":"MNN01ZZ1011","message":"現在システムメンテナンス中のためご利用頂けません。"}\r\n\r\n' | wc --byte
data "template_file" "haproxy_errofile_request_restriction_mode" {
  template = <<-EOF
  HTTP/1.1 503 Service Unavailable
  Content-Type: application/json
  Content-Length: 147

  {"code":"MWN01ZZ1010","message":"アクセスが集中しております。お手数ですが時間をおいて再度お試しください。"}

  EOF
}


#API閉塞
#Content-Length計算方法
#echo -ne '{"code":"MNN01ZZ1011","message":"現在システムメンテナンス中のためご利用頂けません。"}' | wc --bytes
#もし改行の空行があれば、HTMLで改行は(\r\n)ので、計算された結果は↓改行2個入れるのは正解です。
#echo -ne '{"code":"MNN01ZZ1011","message":"現在システムメンテナンス中のためご利用頂けません。"}\r\n\r\n' | wc --byte
data "template_file" "haproxy_errofile_maintenance_mode" {
  template = <<-EOF
  HTTP/1.1 503 Service Unavailable
  Content-Type: application/json
  Content-Length: 114

  {"code":"MNN01ZZ1011","message":"現在システムメンテナンス中のためご利用頂けません。"}

  EOF
}

resource "null_resource" "haproxy_tools" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.haproxy_ssh_hosts)

  triggers = {
    haproxy_ips = join(",", flatten(values(var.haproxy_cluster_hosts)))
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : HAProxy の運用に必要なツールをインストール（インターネット接続が必要）
      sudo -E --askpass yum install -y socat
    EOC
    ]
  }

  connection {
    host        = var.haproxy_ssh_hosts[count.index]
    user        = var.ssh_users[var.haproxy_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.haproxy_ssh_hosts[count.index]]] : null
  }
}
