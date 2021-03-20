#
# Set up Cassandra instances to be able to backup itself
#
resource "null_resource" "setup_for_cassandra_backup" {
  count = length(module.lerna_stack_platform_aws_ec2.cassandra_instance_ips)

  depends_on = [
    module.nfs_instance,
    module.lerna_stack_service_redhat_core
  ]

  triggers = {
    ssh_private_key = filemd5(var.cassandra_backup_user_ssh_private_key_filepath)
    ssh_public_key  = filemd5(var.cassandra_backup_user_ssh_public_key_filepath)
    # TODO Trigger this resource when any backup scripts are updated.
    #   Uncomment below to trigger this resource always if you want.
    #   always = uuid()
  }

  connection {
    host        = module.lerna_stack_platform_aws_ec2.cassandra_instance_ips[count.index]
    user        = module.lerna_stack_platform_aws_ec2.ssh_user
    private_key = file(module.lerna_stack_platform_aws_ec2.ssh_private_key)
  }

  provisioner "file" {
    content     = file(var.cassandra_backup_user_ssh_private_key_filepath)
    destination = "~/cassandra_backup_private_key"
  }

  provisioner "file" {
    content     = file(var.cassandra_backup_user_ssh_public_key_filepath)
    destination = "~/cassandra_backup_public_key"
  }

  provisioner "remote-exec" {
    inline = [<<-EOC

    set -Cex

    ### Set up NFS mount ###

    sudo -E yum install -y nfs-utils

    : Replace the entry /apl/cassandra_backup of /etc/fstab
    sudo sed -e '/\/apl\/cassandra_backup/d' -i.bak /etc/fstab
    echo '${module.nfs_instance.private_ip}:${module.nfs_instance.nfs_export_path} /apl/cassandra_backup nfs defaults,noauto,user 0 0' | sudo tee /etc/fstab

    : Ensure mount directory available
    sudo mkdir -p /apl/cassandra_backup

    : Check whether we can mount /apl/cassandra_backup
    sudo mount /apl/cassandra_backup
    sudo umount /apl/cassandra_backup

    ### Setup a user for cassandra backup ###

    readonly cassandra_backup_user=reactivejob

    : Create a user unless it exists
    if ! grep "$cassandra_backup_user:" /etc/passwd ; then
      sudo useradd "$cassandra_backup_user"
    fi
    : Grant the user as lv4,lv5
    sudo usermod -aG lv4,lv5 "$cassandra_backup_user"
    : Use empty password for the sake of simplicity
    sudo usermod -p '' "$cassandra_backup_user"

    : Ensure .ssh directory exists
    readonly ssh_path="/home/$cassandra_backup_user/.ssh"
    sudo -u "$cassandra_backup_user" mkdir -p "$ssh_path"
    sudo -u "$cassandra_backup_user" chmod 700 "$ssh_path"

    : Replace the private key
    cat cassandra_backup_private_key | sudo -u "$cassandra_backup_user" tee "$ssh_path/id_rsa" > /dev/null
    sudo -u "$cassandra_backup_user" chmod 600 "$ssh_path/id_rsa"
    rm cassandra_backup_private_key

    : Replace the public key
    cat cassandra_backup_public_key | sudo -u "$cassandra_backup_user" tee "$ssh_path/id_rsa.pub"
    sudo -u "$cassandra_backup_user" chmod 644 "$ssh_path/id_rsa.pub"
    cat cassandra_backup_public_key | sudo -u "$cassandra_backup_user" tee -a "$ssh_path/authorized_keys"
    sudo -u "$cassandra_backup_user" sort -u -o "$ssh_path/authorized_keys" "$ssh_path/authorized_keys"
    rm cassandra_backup_public_key

    ### Reconcile scripts ###

    # HACK, this procedure will be broken for the future
    : Replace PROD_HOSTS
    readonly PROD_HOSTS='${join(" ", formatlist("\"%s\"", module.lerna_stack_platform_aws_ec2.cassandra_instance_ips))}'
    sudo sed -e '/^readonly PROD_HOSTS=/s/.*/readonly PROD_HOSTS=\('"$${PROD_HOSTS}"'\)/' \
       -i.bak /opt/management/bin/APP_cassandra_backup_kick.sh

    # HACK, this procedure will be broken for the future
    : Replace SSH User
    sudo sed -e '/^readonly SSH_USER=/s/.*/readonly SSH_USER="'"$cassandra_backup_user"'"/' \
       -i.bak /opt/management/bin/APP_cassandra_backup_kick.sh

    EOC
    ]
  }

}

// NFS is used by cassandra backup scripts
module "nfs_instance" {
  source = "./modules/nfs-instance"

  instance_type     = "t2.medium"
  keypair_key_name  = aws_key_pair.nfs_instance.key_name
  private_ip        = var.nfs_instance_private_ip
  security_group_id = var.aws_vpc_security_group_id
  ssh_private_key   = file(var.ssh_private_key_file_path)
  subnet_id         = var.aws_vpc_subnet_id
  tags = {
    Name = "${var.name_prefix}-nfs-instance"
  }

}

// KeyPair that is used by nfs_instance
resource "aws_key_pair" "nfs_instance" {
  key_name_prefix = "${var.name_prefix}-nfs-instance-"
  public_key      = file(var.ssh_public_key_file_path)
  tags = {
    Name = "${var.name_prefix}-nfs-instance"
  }
}
