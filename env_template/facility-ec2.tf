module "ec2" {
  source = "../modules/platform/aws/ec2"

  # [必須] AWS アクセスキー ID
  //aws_access_key = "AKIAxxxxxxxxxxxxxxxxxxxxxxx"

  # [必須] AWS アクセスキー Secret
  //aws_secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

  # Amazon マシンイメージ（AMI）（デフォルト：CentOS Linux 8 x86_64）
  //aws_ami = "ami-089a156ea4f52a0a3"

  # [必須] セキュリティグループの ID
  //aws_vpc_security_group_id = "sg-xxxxxxxxxxxxxxxxx"

  # [必須] サブネットの ID
  //aws_vpc_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"

  # [必須] ルートテーブルの書き換えが可能なポリシーを持つロール
  //aws_keepalived_instance_role_name = "xxxxxxxxxx"

  # [必須] 仮想 IP を付与するルートテーブル
  //aws_vpc_route_table_id_for_virtual_ips = "rtb-xxxxxxxxxxxxxxxxx"

  # [必須] HTTP プロキシのホスト名/IP
  //http_proxy_host = "xxx.xxx.xxx.xxx"

  # HTTP プロキシのポート番号
  //http_proxy_port = 3128

  # Keepalived の VRRP で利用する NIC の名前
  //keepalived_vrrp_network_interface = "eth0"

  # SSH で利用するユーザー（設定する名前は AMI に依存）
  //ssh_user = "centos"

  # SSH 公開鍵のパス
  //ssh_public_key = "~/.ssh/id_rsa.pub"

  # SSH 秘密鍵のパス
  //ssh_private_key = "~/.ssh/id_rsa"

  # [必須] リソースの命名に含めるプレフィックス。誰が作ったリソースか識別するのに利用する
  //name_prefix = "lerna-user1"

  # Keepalived サーバーのインスタンスタイプ
  //keepalived_instance_type = "c5.large"

  # HAProxy サーバーのインスタンスタイプ
  //haproxy_instance_type = "c5.large"

  # アプリケーションサーバーのインスタンスタイプ
  //app_instance_type = "r5.large"

  # Cassandra サーバーのインスタンスタイプ
  //cassandra_instance_type = "r5.xlarge"

  # MariaDB サーバーのインスタンスタイプ
  //mariadb_instance_type = "r5.large"

  # Gatlingホストのインスタンスタイプ
  //gatling_instance_type = "r5.large"

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
  //keepalived_private_ips = []

  # [必須] HAProxy サーバーの Private IP リスト
  //haproxy_private_ips = []

  # [必須] Application サーバーの Private IP リスト
  //app_private_ips = []

  # [必須] Cassandra サーバーの Private IP リスト
  //cassandra_private_ips = []

  # [必須] MariaDB サーバーの Private IP リスト
  //mariadb_private_ips = []

  # Gatling サーバーの Private IP リスト
  //gatling_private_ips = []

  # [必須] Keepalived が付与する仮想 IP（サブネットの範囲外の IP を指定）
  //keepalived_virtual_ips = ["192.168.100.100"]
}
