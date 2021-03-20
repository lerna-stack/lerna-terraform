#
# NFS Instance (Only For Development)
#
# WARNINGS
#   This script is not well designed about security and availability.
#   If we launch an NFS server or service in production, use an alternative solutions such as Amazon EFS.
#

resource "aws_instance" "nfs_instance" {
  subnet_id     = var.subnet_id
  instance_type = var.instance_type
  ami           = var.ami
  key_name      = var.keypair_key_name
  private_ip    = var.private_ip

  source_dest_check = false

  vpc_security_group_ids = [
    var.security_group_id,
  ]

  tags = var.tags
}

resource "null_resource" "setup_for_nfs_instance" {
  triggers = {
    nfs_instance = aws_instance.nfs_instance.id
    etc_exports  = md5(data.template_file.etc_exports.rendered)
  }

  connection {
    host        = aws_instance.nfs_instance.private_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key
  }

  provisioner "file" {
    content     = data.template_file.etc_exports.rendered
    destination = "~/etc_exports"
  }

  provisioner "remote-exec" {
    inline = [<<-EOC

    set -Cex

    sudo -E yum install -y nfs-utils

    # Only For Development
    # It would be better to use strict access control.
    cat etc_exports | sudo tee /etc/exports
    rm etc_exports
    sudo mkdir -p "${var.nfs_export_path}"
    sudo chmod 777 "${var.nfs_export_path}"

    sudo systemctl restart nfs-server
    sudo systemctl enable nfs-server

    EOC
    ]
  }
}

data "template_file" "etc_exports" {
  template = <<-EOF

  # Only For Development
  # It would be better to use more strict access control.
  ${var.nfs_export_path} (rw)

  EOF
}
