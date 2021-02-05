locals {
  dist_name = var.use_rhel ? "rhel7" : "centos8"
  dist_conf = {
    // CentOS Linux 8 x86_64
    centos8 = {
      ami       = "ami-089a156ea4f52a0a3"
      ssh_user  = "centos"
      cx_large  = "c5.large"
      rx_large  = "r5.large"
      rx_xlarge = "r5.xlarge"
    }
    // RedHat Enterprise Linux 7.2 x86_64
    // RHEL7 を使う場合には追加の料金を払う必要があるため注意してください。
    // https://aws.amazon.com/marketplace/pp/B019NS7T5I?qid=1612505340203&sr=0-2&ref_=srh_res_product_title
    rhel7 = {
      ami       = "ami-0dd8f963"
      ssh_user  = "ec2-user"
      cx_large  = "c4.large"
      rx_large  = "r3.large"
      rx_xlarge = "r3.xlarge"
    }
  }
}

module "lerna_stack_platform_aws_ec2" {
  source = "../../modules/platform/aws/ec2"

  # [必須] AWS APIキー変数設定
  aws_access_key = var.aws_access_key

  # [必須] AWS API Secret Key 変数設定
  aws_secret_key = var.aws_secret_key

  # Amazon マシンイメージ（AMI）
  aws_ami = local.dist_conf[local.dist_name]["ami"]

  # [必須] セキュリティグループのID
  aws_vpc_security_group_id = var.aws_vpc_security_group_id

  # [必須] サブネットのID
  aws_vpc_subnet_id = var.aws_vpc_subnet_id

  # [必須] ルートテーブルの書き換えが可能なポリシーを持つロール
  aws_keepalived_instance_role_name = "keepalived_instance_role"

  # [必須] 仮想IPを付与するルートテーブル
  aws_vpc_route_table_id_for_virtual_ips = var.aws_vpc_route_table_id_for_virtual_ips

  # [必須] HTTP プロキシのホスト名/IP
  http_proxy_host = var.http_proxy_host

  # HTTP プロキシのポート番号
  //http_proxy_port = 3128

  # Keepalived の VRRP で利用する NIC の名前
  //keepalived_vrrp_network_interface = "eth0"

  # SSH で利用するユーザー（設定する名前は AMI に依存）
  ssh_user = local.dist_conf[local.dist_name]["ssh_user"]

  # SSH 公開鍵のパス
  //ssh_public_key = "~/.ssh/id_rsa.pub"

  # SSH 秘密鍵のパス
  //ssh_private_key = "~/.ssh/id_rsa"

  # [必須] リソースの命名に含めるプレフィックス。誰が作ったリソースか識別するのに利用する
  name_prefix = var.name_prefix

  # Keepalived サーバーのインスタンスタイプ
  keepalived_instance_type = local.dist_conf[local.dist_name]["cx_large"]

  # HAProxy サーバーのインスタンスタイプ
  haproxy_instance_type = local.dist_conf[local.dist_name]["cx_large"]

  # アプリケーションサーバーのインスタンスタイプ
  app_instance_type = local.dist_conf[local.dist_name]["rx_large"]

  # Cassandra サーバーのインスタンスタイプ
  cassandra_instance_type = local.dist_conf[local.dist_name]["rx_xlarge"]

  # MariaDB サーバーのインスタンスタイプ
  mariadb_instance_type = local.dist_conf[local.dist_name]["rx_large"]

  # Gatlingホストのインスタンスタイプ
  gatling_instance_type = local.dist_conf[local.dist_name]["rx_large"]

  # Keepalived サーバーの ディスク容量
  //keepalived_volume_size_gb = 16

  # HAProxy サーバーのディスク容量（単位：GB）
  //haproxy_volume_size_gb = 16

  # アプリケーションサーバーのディスク容量（単位：GB）
  //app_volume_size_gb = 16

  # Cassandra サーバーのディスク容量（単位：GB）
  //cassandra_volume_size_gb = 64

  # MariaDB サーバーのディスク容量（単位：GB）
  //mariadb_volume_size_gb = 64

  # Gatling サーバーのディスク容量（単位：GB）
  //gatling_volume_size_gb = 64

  # [必須] Keepalived サーバーの Private IP リスト
  keepalived_private_ips = var.keepalived_private_ips

  # [必須] HAProxy サーバーの Private IP リスト
  haproxy_private_ips = var.haproxy_private_ips

  # [必須] Application サーバーの Private IP リスト
  app_private_ips = var.app_private_ips

  # [必須] Cassandra サーバーの Private IP リスト
  cassandra_private_ips = var.cassandra_private_ips

  # [必須] MariaDB サーバーの Private IP リスト
  mariadb_private_ips = var.mariadb_private_ips

  # Gatling サーバーの Private IP リスト
  gatling_private_ips = var.gatling_private_ips

  # [必須] Keepalived が付与する仮想 IP（サブネットの範囲外のIPを指定）
  keepalived_virtual_ips = var.keepalived_virtual_ips
}
