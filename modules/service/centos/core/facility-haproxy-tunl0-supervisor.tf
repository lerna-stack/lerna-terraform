resource "null_resource" "haproxy_tunl0_supervisor" {
  depends_on = [null_resource.management_script_global]
  count      = length(var.haproxy_ssh_hosts)

  triggers = {
    tunl0-supervisor_sh      = filemd5("${path.module}/resources/tunl0-supervisor/tunl0-supervisor.sh")
    tunl0-supervisor_service = md5(data.template_file.tunnel_nic_monitoring_service.rendered)
    tunl0_virtual_ips        = md5(data.template_file.tunl0_virtual_ips.rendered)
  }

  provisioner "file" {
    source      = "${path.module}/resources/tunl0-supervisor/tunl0-supervisor.sh"
    destination = "/tmp/tunl0-supervisor.sh"
  }

  provisioner "file" {
    content     = data.template_file.tunl0_virtual_ips.rendered
    destination = "/tmp/virtual-ips_${local.section_id}"
  }

  provisioner "file" {
    content     = data.template_file.tunnel_nic_monitoring_service.rendered
    destination = "/tmp/tunl0-supervisor.service"
  }

  provisioner "remote-exec" {
    inline = [<<EOC
      source /etc/profile; export SUDO_ASKPASS="${local.sudo_askpass_path}"; set -ex

      sudo --askpass install --owner=root --group=lv4 --mode=0755 --directory /etc/tunl0-supervisor/
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/virtual-ips_${local.section_id} /etc/tunl0-supervisor/virtual-ips_section_${local.section_id}
      cat /etc/tunl0-supervisor/virtual-ips_section_* > /tmp/virtual-ips
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/virtual-ips /etc/tunl0-supervisor/virtual-ips

      sudo --askpass install --owner=root --group=lv4 --mode=0764 /tmp/tunl0-supervisor.sh /usr/local/bin/tunl0-supervisor.sh
      sudo --askpass install --owner=root --group=lv4 --mode=0664 /tmp/tunl0-supervisor.service /usr/lib/systemd/system/tunl0-supervisor.service

      sudo systemctl enable tunl0-supervisor.service

      rm /tmp/virtual-ips_${local.section_id}
      rm /tmp/virtual-ips
      rm /tmp/tunl0-supervisor.sh
      rm /tmp/tunl0-supervisor.service
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

data "template_file" "tunl0_virtual_ips" {
  template = <<-EOF
  ${join("\n", values(var.keepalived_virtual_ips))}
  EOF
}

data "template_file" "tunnel_nic_monitoring_service" {
  template = <<-EOF
  [Unit]
  Description = ipip tunnelling service
  After = network.target

  [Service]
  Type = simple
  ExecStart = /usr/local/bin/tunl0-supervisor.sh
  Restart = always
  RestartSec = 3

  [Install]
  WantedBy = multi-user.target
EOF
}
