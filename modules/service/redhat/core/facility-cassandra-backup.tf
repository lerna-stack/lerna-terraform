
resource "null_resource" "cassandra_backup" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.cassandra_ssh_hosts)

  triggers = {
    cassandra_backup_kick      = filemd5("${path.module}/resources/cassandra/backup/APP_cassandra_backup_kick.sh")
    cassandra_mount            = filemd5("${path.module}/resources/cassandra/backup/APP_cassandra_mount.sh")
    cassandra_backup_keyspaces = md5(data.template_file.cassandra_backup_keyspace_maping_section.*.rendered[count.index])
  }

  provisioner "remote-exec" {
    inline = [<<-EOC
    source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

    mkdir -p /tmp/backup_cassandra
    mkdir -p /tmp/backup_cassandra/config
    EOC
    ]
  }

  provisioner "file" {
    source      = "${path.module}/resources/cassandra/backup/"
    destination = "/tmp/backup_cassandra"
  }

  provisioner "file" {
    content     = data.template_file.cassandra_backup_keyspace_maping_section.*.rendered[count.index]
    destination = "/tmp/backup_cassandra/config/backup_keyspaces_section_${local.section_id}.conf"
  }

  # Setup cassandra
  provisioner "remote-exec" {
    inline = [<<-EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      sudo --askpass install --owner=root --group=lv5 --mode=0750 /tmp/backup_cassandra/APP_cassandra_backup_kick.sh  /opt/management/bin
      sudo --askpass install --owner=root --group=lv5 --mode=0750 /tmp/backup_cassandra/APP_cassandra_backup.sh  /opt/management/bin
      sudo --askpass install --owner=root --group=lv5 --mode=0750 /tmp/backup_cassandra/APP_cassandra_mount.sh  /opt/management/bin
      # backup keyspace
      sudo --askpass install --mode=775 --owner=root --group=lv4 --directory /opt/management/config
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/backup_cassandra/config/backup_keyspaces_section_${local.section_id}.conf /opt/management/config
      cat /opt/management/config/backup_keyspaces_section_*.conf > /tmp/backup_cassandra/config/backup_keyspaces.conf
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/backup_cassandra/config/backup_keyspaces.conf /opt/management/config
      rm -rf /tmp/backup_cassandra
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


data "template_file" "cassandra_backup_keyspace_maping_section" {

  count = length(var.cassandra_cluster_hosts)

  template = <<-EOF
  # テナントごとのCassandra Keyspace Mapping ${local.section_id}
  %{for tenant in var.active_tenants}
  # tenant-id    keyspace
  %{for keyspace in var.cassandra_keyspaces[tenant]}
  ${tenant}      ${keyspace}
  %{endfor}
  %{endfor}
EOF
}

