locals {
  mariadb_repo_file = file("${path.module}/resources/mariadb/mariadb_${var.mariadb_yum_repository_distribution_name}.repo")
}

resource "null_resource" "mariadb" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.mariadb_ssh_hosts)

  triggers = {
    mariadb_repo = md5(local.mariadb_repo_file)
  }

  provisioner "file" {
    content     = local.mariadb_repo_file
    destination = "/tmp/MariaDB.repo"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Install MariaDB
      # https://mariadb.com/kb/en/yum/
      sudo --askpass install --owner=root --group=root --mode=0664 /tmp/MariaDB.repo /etc/yum.repos.d/MariaDB.repo
      # 依存エラーを回避するため boost-devel をインストール Failed dependencies: libboost_program_options.so...
      # https://mariadb.com/kb/en/mariadb-installation-version-10121-via-rpms-on-centos-7/
      sudo --askpass -E yum install -y boost-devel.x86_64
      #  Problem: cannot install the best candidate for the job
      #    nothing provides socat needed by galera-4-26.4.5-1.el8.x86_64
      sudo --askpass -E yum install -y socat

      # --disablerepo=appstream を指定して、MariaDB がインストールできない問題を回避
      # https://forums.centos.org/viewtopic.php?t=71881#post_content302560
      # CentOS かつ appstream のリポジトリファイルがある場合にのみ無効にするためにファイルの有無をチェックする
      if [[ -f /etc/yum.repos.d/CentOS-Linux-AppStream.repo ]]; then
        readonly YUM_OPTS="--disablerepo=appstream"
      else
        readonly YUM_OPTS=""
      fi
      sudo --askpass -E yum install -y $YUM_OPTS MariaDB-server galera-4 MariaDB-client MariaDB-backup MariaDB-common

      : Enable MariaDB Service
      sudo --askpass systemctl enable mariadb

      : cleanup
      rm /tmp/MariaDB.repo
    EOC
    ]
  }

  connection {
    host        = var.mariadb_ssh_hosts[count.index]
    user        = var.ssh_users[var.mariadb_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.mariadb_ssh_hosts[count.index]]] : null
  }
}

resource "null_resource" "mariadb_config" {
  count = length(var.mariadb_ssh_hosts)

  triggers = {
    mariadb    = null_resource.mariadb.*.id[count.index]
    galera_cnf = md5(data.template_file.galera_cnf.*.rendered[count.index])
  }

  provisioner "file" {
    content     = data.template_file.galera_cnf.*.rendered[count.index]
    destination = "/tmp/galera.cnf"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      : Config MariaDB
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/galera.cnf /etc/my.cnf.d/galera.cnf

      : Cleanup
      rm /tmp/galera.cnf
    EOC
    ]
  }

  connection {
    host        = var.mariadb_ssh_hosts[count.index]
    user        = var.ssh_users[var.mariadb_ssh_hosts[count.index]]
    private_key = var.ssh_private_key != null ? file(var.ssh_private_key) : null
    password    = var.ssh_passwords != null ? var.ssh_passwords[var.ssh_users[var.mariadb_ssh_hosts[count.index]]] : null
  }
}

data "template_file" "galera_cnf" {
  count = length(var.mariadb_ssh_hosts)

  template = <<-EOF
  [galera]
  # Mandatory settings
  wsrep_on=ON
  wsrep_provider=/usr/lib64/galera-4/libgalera_smm.so
  wsrep_node_address=${var.mariadb_cluster_hosts[count.index]}
  wsrep_cluster_address=gcomm://${join(",", var.mariadb_cluster_hosts)}
  # wsrep_slave_threads is not equal to 2, 3 or 4 times number of CPU(s)
  wsrep_slave_threads=2
  wsrep_provider_options="gcs.fc_factor=0.8;gcs.fc_limit=10;"
  binlog_format=row
  default_storage_engine=InnoDB
  innodb_autoinc_lock_mode=2
  innodb_flush_log_at_trx_commit=0
  innodb_buffer_pool_size=6G
  # Allow server to accept connections on all interfaces.
  bind-address=0.0.0.0

  [mysqld]
  max_connections = 500
  EOF
}
