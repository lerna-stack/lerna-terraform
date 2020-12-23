resource "null_resource" "security_settings" {
  count = length(local.instance_private_ips)

  provisioner "remote-exec" {
    inline = [<<EOC
      set -xe

      : Disable sudo requiretty
      echo "Defaults:${var.ssh_user} !requiretty" | sudo tee /etc/sudoers.d/not_requiretty

      : Disable SE Linux temporarily
      sudo setenforce Permissive || : SELinux already disabled  # 警告すら出したくないので、できれば Disabled にしたいが指定できないので Permissive で代用

      : Disable SE Linux permanently
      sudo sed --in-place -E 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    EOC
    ]
  }

  connection {
    host        = local.instance_private_ips[count.index]
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }
}
