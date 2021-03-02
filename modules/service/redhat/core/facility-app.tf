resource "null_resource" "app" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.app_ssh_hosts)

  triggers = {
    app_ips              = join(",", var.app_cluster_hosts)
    app_rpm              = filemd5(var.app_rpm_path)
    app_rpm_name         = basename(var.app_rpm_path)
    app_application_ini  = md5(data.template_file.app_application_ini.*.rendered[count.index])
    app_conf             = md5(data.template_file.app_conf.*.rendered[count.index])
    app_service_override = md5(data.template_file.app_service_override.rendered)
  }

  provisioner "file" {
    source      = var.app_rpm_path
    destination = "/tmp/app.rpm"
  }

  provisioner "file" {
    content     = data.template_file.app_application_ini.*.rendered[count.index]
    destination = "/tmp/app.application.ini"
  }

  provisioner "file" {
    content     = data.template_file.app_conf.*.rendered[count.index]
    destination = "/tmp/app.conf"
  }

  provisioner "file" {
    content     = data.template_file.app_service_override.rendered
    destination = "/tmp/app.service.override"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Install applicaiton
      sudo --askpass -E yum install -y /tmp/app.rpm --disableexcludes=all # app は yum の自動更新対象外にしているため

      : Place Service config file
      sudo --askpass install -D --owner=root --group=lv4 --mode=0664 /tmp/app.service.override /etc/systemd/system/${var.app_service_name}.service.d/override.conf
      rm /tmp/app.service.override

      : Enable Service
      sudo --askpass systemctl daemon-reload
      sudo --askpass systemctl enable ${var.app_service_name}.service

      : Place config file
      sudo --askpass install --owner=root --group=lv4 --mode=0755 --directory ${var.app_install_dir}/${var.app_service_name}/conf
      sudo --askpass install --owner=${var.app_service_user} --group=lv4 --mode=0440 /tmp/app.application.ini  ${var.app_install_dir}/${var.app_service_name}/conf/application.ini
      sudo --askpass install --owner=${var.app_service_user} --group=lv4 --mode=0440 /tmp/app.conf ${var.app_install_dir}/${var.app_service_name}/conf/app.conf
      : clean up
      rm /tmp/app.rpm
      rm /tmp/app.application.ini
      rm /tmp/app.conf
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

/*
 * システムプロパティ の設定
 * ps コマンドでサーバーにログインできるユーザーが全員閲覧できるので、機密情報をここに含めるのは厳禁。
 * 機密情報はアプリが直接ロードする data.template_file.app_conf に設定すること。
 * システムプロパティに機密情報を書かざるを得ない場合は、別途対応方針を決める。
 */
data "template_file" "app_application_ini" {
  count    = length(var.app_cluster_hosts)
  template = <<-EOF
  -J-XX:+HeapDumpOnOutOfMemoryError
  -J-XX:HeapDumpPath=${var.app_dump_dir}/${var.app_service_name}
  -J-XX:ErrorFile==${var.app_dump_dir}/${var.app_service_name}/java_error_%p.log
  -Dconfig.file=${var.app_install_dir}/${var.app_service_name}/conf/app.conf
  -Djava.net.preferIPv4Stack=true
  -Dcom.sun.management.jmxremote=true
  -Dcom.sun.management.jmxremote.host=0.0.0.0
  -Dcom.sun.management.jmxremote.port=${var.app_jmx_port}
  -Dcom.sun.management.jmxremote.rmi.port=${var.app_jmx_port}
  -Dcom.sun.management.jmxremote.ssl=false
  -Dcom.sun.management.jmxremote.authenticate=false
  ${var.app_arguments == null ? "" : var.app_arguments[count.index]}
  EOF
}

/*
 * アプリの設定
 * 参照：https://github.com/lightbend/config
 */
data "template_file" "app_conf" {
  count    = length(var.app_cluster_hosts)
  template = <<-EOF
  # include the original default config file
  # after the include statement you could go on to override certain settings.
  # see: https://github.com/lightbend/config#standard-behavior
  include "application"

  datastax-java-driver.profiles.akka-persistence-cassandra-profile.basic.request.consistency = "LOCAL_QUORUM"
  datastax-java-driver.profiles.akka-persistence-cassandra-snapshot-profile.basic.request.consistency = "LOCAL_QUORUM"
  %{for contact-point in var.cassandra_service_hosts}
  datastax-java-driver.basic.contact-points.${index(var.cassandra_service_hosts, contact-point)} = "${contact-point}:${local.cassandra_native_transport_port}"
  %{endfor}
  datastax-java-driver.basic.load-balancing-policy.local-datacenter = "${var.cassandra_local_data_center_id}"
  # cassandra driverのタイムアウトはデフォルト5000ms + 12000ms
  # https://github.com/akka/akka-persistence-cassandra/blob/master/core/src/main/resources/reference.conf#L325-L329
  akka.persistence.cassandra.journal.circuit-breaker.call-timeout = "20s"
  akka.remote.artery.transport = tcp
  akka.remote.artery.canonical.hostname = "${var.app_cluster_hosts[count.index]}"
  akka.remote.artery.canonical.port = ${var.app_akka_cluster_port}

  # Akka Cluster
  # see: https://doc.akka.io/docs/akka/current/general/configuration.html#akka-cluster
  %{for app_cluster_ip in var.app_cluster_hosts}
  akka.cluster.seed-nodes.${index(var.app_cluster_hosts, app_cluster_ip)} = "akka://${var.app_akka_actor_system_name}@${app_cluster_ip}:${var.app_akka_cluster_port}"
  %{endfor}
  akka.cluster.unreachable-nodes-reaper-interval = "500ms"
  akka.cluster.min-nr-of-members = ${local.app_cluster_quorum_size}
  akka.cluster.down-removal-margin = "3.5s"
  akka.cluster.failure-detector.heartbeat-interval = "500ms"
  akka.cluster.failure-detector.acceptable-heartbeat-pause = "1200ms"
  akka.cluster.failure-detector.threshold = 8.0

  # Akka Split Brain Resolver
  # see: https://doc.akka.io/docs/akka-enhancements/current/split-brain-resolver.html
  akka.cluster.downing-provider-class = "akka.cluster.sbr.SplitBrainResolverProvider"
  akka.cluster.split-brain-resolver.active-strategy = "static-quorum"
  akka.cluster.split-brain-resolver.static-quorum.quorum-size = ${local.app_cluster_quorum_size}
  # down-removal-margin と同一の値が推奨値
  akka.cluster.split-brain-resolver.stable-after = "3.5s"
  akka.cluster.split-brain-resolver.down-all-when-unstable = "off"

  ####### 各種タイムアウト #######
  akka.http.server.idle-timeout = "570s"
  akka.http.server.request-timeout = "565s"

  ####### 外部リクエストのコネクションプール設定 #######
  # [HAProxy側の流量制限の値] * [HAProxyの台数] より大きくする
  akka.http.host-connection-pool.max-connections = ${local.app_host_connection_pool_max_connection}
  # max-connections より大きくする (※ 2^N にする必要あり)
  akka.http.host-connection-pool.max-open-requests = ${pow(2, ceil(log(local.app_host_connection_pool_max_connection * 4, 2)))}
  # gateway timeout より長くする
  akka.http.host-connection-pool.client.idle-timeout = "120s"

  %{if var.app_disable_ssl_hostname_verification}
  akka.ssl-config.loose.disableHostnameVerification = "true"
  %{endif}

  ${var.app_configs[count.index]}
  EOF
}

locals {
  # 外部リクエストのコネクションプール設定
  # [HAProxy側の流量制限の値] * [HAProxyの台数] より大きくする
  # sum 関数が実装されていないためこのような実装になっていること、結果は 1024 までの制限があり
  app_host_connection_pool_max_connection = (length(flatten([for e in flatten([values(var.haproxy_max_connection)]) : range(e)]))) * length(var.app_cluster_hosts)
}


data "template_file" "app_service_override" {
  template = <<-EOF
  [Service]
  Environment="JAVA_HOME=${var.app_java_home}"
  LimitNOFILE=1048576
  LimitNPROC=32768
  LimitAS=infinity
  EOF
}
