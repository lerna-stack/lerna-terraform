locals {
  cassandra_native_transport_port = 9042

  cassandra_rack_ids = { for h in var.cassandra_ssh_hosts : h => transpose(var.cassandra_availability_zones)[h][0] }
}

resource "null_resource" "cassandra" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.cassandra_ssh_hosts)

  triggers = {
    instance_cassandra = var.cassandra_service_hosts[count.index]
    cassandra_rpm      = filemd5(var.cassandra_rpm_path)
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    mkdir -p /tmp/cassandra
    EOC
    ]
  }

  provisioner "file" {
    source      = var.cassandra_rpm_path
    destination = "/tmp/cassandra/cassandra.rpm"
  }

  # Setup cassandra
  provisioner "remote-exec" {
    inline = [<<-EOC
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    sudo --askpass yum install -y /tmp/cassandra/cassandra.rpm --disableexcludes='all' --exclude='jre' # インフラチームがJDKをインストール

    : cleanup
    rm -rf /tmp/cassandra
    EOC
    ]
  }

  connection {
    host        = var.cassandra_ssh_hosts[count.index]
    user        = var.ssh_users[var.cassandra_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.cassandra_ssh_hosts[count.index]]] : null
  }
}

resource "null_resource" "cassandra_config" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.cassandra_ssh_hosts)

  triggers = {
    cassandra                   = null_resource.cassandra.*.id[count.index]
    cassandra_sysctl            = md5(data.template_file.cassandra_sysctl.rendered)
    cassandra_host              = md5(data.template_file.cassandra_profile.*.rendered[count.index])
    cassandra_service           = md5(data.template_file.cassandra_service.*.rendered[count.index])
    cassandra_yaml              = md5(data.template_file.cassandra_yaml.*.rendered[count.index])
    cassandra-rackdc_properties = md5(data.template_file.cassandra-rackdc_properties.*.rendered[count.index])
    jvm_options                 = md5(data.template_file.jvm_options.*.rendered[count.index])
    cassandra_conf              = data.archive_file.cassandra_conf.output_md5
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    mkdir -p /tmp/cassandra
    mkdir -p /tmp/cassandra/conf
    EOC
    ]
  }

  provisioner "file" {
    content     = data.template_file.cassandra_sysctl.rendered
    destination = "/tmp/cassandra/99-cassandra.conf"
  }

  provisioner "file" {
    content     = data.template_file.cassandra_profile.*.rendered[count.index]
    destination = "/tmp/cassandra/profile.cassandra-host.sh"
  }

  provisioner "file" {
    content     = data.template_file.cassandra_service.*.rendered[count.index]
    destination = "/tmp/cassandra/cassandra.service"
  }

  provisioner "file" {
    content     = data.template_file.cassandra_yaml.*.rendered[count.index]
    destination = "/tmp/cassandra/conf/cassandra.yaml"
  }

  provisioner "file" {
    content     = data.template_file.cassandra-rackdc_properties.*.rendered[count.index]
    destination = "/tmp/cassandra/conf/cassandra-rackdc.properties"
  }

  provisioner "file" {
    content     = data.template_file.jvm_options.*.rendered[count.index]
    destination = "/tmp/cassandra/conf/jvm.options"
  }

  # 回復オペレーションの際にこのファイルを編集する必要があるため、triggers指定はしないこと
  provisioner "file" {
    source      = "${path.module}/resources/cassandra/conf/"
    destination = "/tmp/cassandra/conf"
  }

  # Put config files
  provisioner "remote-exec" {
    inline = [<<-EOC
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    : Apply system parameters
    sudo install --owner=root --mode=0644 /tmp/cassandra/99-cassandra.conf /etc/sysctl.d/99-cassandra.conf
    sudo sysctl --load=/etc/sysctl.d/99-cassandra.conf

    : Place profile
    sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/cassandra/profile.cassandra-host.sh /etc/profile.d/cassandra-host.sh

    : Reset configuration to defualt
    sudo --askpass install -D --owner=root --group=lv4 --mode=0664 --backup=off /etc/cassandra/default.conf/* /etc/cassandra/conf/ || : no change
    : Overwrite configuration
    sudo --askpass install -D --owner=root --group=lv4 --mode=0664 /tmp/cassandra/conf/* /etc/cassandra/conf/

    : Create directory to store jvm heapdump
    sudo --askpass install --directory --owner=cassandra  --group=lv4 --mode=0775 /apl/var/log/cassandra

    : Configure systemd
    sudo --askpass install --owner=root --mode=0664 /tmp/cassandra/cassandra.service /etc/systemd/system/
    sudo --askpass systemctl daemon-reload
    sudo --askpass systemctl enable cassandra.service

    : cleanup
    rm -rf /tmp/cassandra
    EOC
    ]
  }

  connection {
    host        = var.cassandra_ssh_hosts[count.index]
    user        = var.ssh_users[var.cassandra_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.cassandra_ssh_hosts[count.index]]] : null
  }
}

data "template_file" "cassandra_sysctl" {
  template = <<-EOF
  vm.max_map_count = 1048575
  net.ipv4.tcp_keepalive_time = 60
  net.ipv4.tcp_keepalive_probes = 3
  net.ipv4.tcp_keepalive_intvl = 10
  net.core.rmem_max = 16777216
  net.core.wmem_max = 16777216
  net.core.rmem_default = 16777216
  net.core.wmem_default = 16777216
  net.core.optmem_max = 40960
  net.ipv4.tcp_rmem = 4096 87380 16777216
  net.ipv4.tcp_wmem = 4096 65536 16777216
  EOF
}

data "template_file" "cassandra_profile" {
  count = length(var.cassandra_service_hosts)

  template = <<-EOF
  export CQLSH_HOST=${var.cassandra_service_hosts[count.index]}
  EOF
}

data "template_file" "cassandra_service" {
  count = length(var.cassandra_service_hosts)

  template = <<-EOF
  # /usr/lib/systemd/system/cassandra.service
  [Unit]
  Description=Cassandra
  After=network.target

  [Service]
  User=cassandra
  Group=cassandra
  Environment="JAVA_HOME=${var.cassandra_java_home}"
  ExecStart=/usr/sbin/cassandra -f
  StandardOutput=journal
  StandardError=journal
  LimitNOFILE=1048576
  LimitMEMLOCK=infinity
  LimitNPROC=32768
  LimitAS=infinity
  Restart=always
  RestartSec=30

  [Install]
  WantedBy=multi-user.target
  EOF
}

data "template_file" "cassandra_yaml" {
  count    = length(var.cassandra_service_hosts)
  template = file("${path.module}/resources/cassandra/templates/cassandra.yaml")
  vars = {
    self_service_private_ip   = var.cassandra_service_hosts[count.index]
    self_operation_private_ip = var.cassandra_cluster_hosts[count.index]
    seed_private_ip           = join(",", var.cassandra_seed_private_ips)
    native_transport_port     = local.cassandra_native_transport_port
  }
}

data "template_file" "cassandra-rackdc_properties" {
  count    = length(var.cassandra_service_hosts)
  template = file("${path.module}/resources/cassandra/templates/cassandra-rackdc.properties")
  vars = {
    data_center_id = var.cassandra_local_data_center_id
    rack_id        = local.cassandra_rack_ids[var.cassandra_ssh_hosts[count.index]]
  }
}

data "template_file" "jvm_options" {
  count    = length(var.cassandra_service_hosts)
  template = file("${path.module}/resources/cassandra/templates/jvm.options")
  vars = {
    self_private_ip = var.cassandra_service_hosts[count.index]
  }
}

/**
 * conf の変更を検知するための workaround
 * Can Terraform watch a directory for changes? - Stack Overflow
 * https://stackoverflow.com/questions/51138667/can-terraform-watch-a-directory-for-changes#answer-54815973
 */
data "archive_file" "cassandra_conf" {
  type        = "zip"
  source_dir  = "${path.module}/resources/cassandra/conf"
  output_path = "${path.module}/resources/cassandra/conf.zip"
}

output "cassandra_first_installed_message" {
  value = <<-EOF

    system_authのreplication_factorはデフォルト1で初回起動するため、cassandra初回起動後は以下のコマンドを実行すること
    1つめのコマンドは本番とDRの各1ノード(2ノード)だけで良い
    2つめのコマンド実行時 system_auth の replication_factor が全ノードで 3 になっていることを確認すること
    $ cqlsh -u cassandra -e "alter keyspace "system_auth" with replication = {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '3'};"
    $ cqlsh -u cassandra -e "SELECT * FROM system_schema.keyspaces;"
  EOF
}

resource "null_resource" "cassandra_tools" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.cassandra_ssh_hosts)

  triggers = {
    instance_cassandra = var.cassandra_service_hosts[count.index]
    cassandra_rpm      = filemd5(var.cassandra_rpm_path)
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Cassandra の運用に必要なツールをインストール（インターネット接続が必要）
      # cqlsh が python2 に依存する
      # https://support.datastax.com/hc/en-us/articles/115000180726--No-appropriate-python-interpreter-found-when-running-cqlsh
      sudo -E yum install -y python2
      # 'python' コマンドを python2 に向ける
      # RHEL7 では python が登録されていないため --install してから --set することでエラー発生を回避する
      sudo alternatives --install /usr/bin/unversioned-python python /usr/bin/python2 10
      sudo alternatives --set python /usr/bin/python2
      EOC
    ]
  }

  connection {
    host        = var.cassandra_ssh_hosts[count.index]
    user        = var.ssh_users[var.cassandra_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.cassandra_ssh_hosts[count.index]]] : null
  }
}
