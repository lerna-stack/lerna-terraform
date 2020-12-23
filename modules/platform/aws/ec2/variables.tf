variable "aws_access_key" {
  description = "AWS アクセスキー ID"
  # example = "AKIAxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "aws_secret_key" {
  description = "AWS アクセスキー Secret"
  # example = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "aws_ami" {
  // https://wiki.centos.org/Cloud/AWS
  description = "Amazon マシンイメージ（AMI）（デフォルト：CentOS Linux 8 x86_64）"
  default     = "ami-089a156ea4f52a0a3"
}

variable "aws_vpc_security_group_id" {
  description = "セキュリティグループの ID"
  # example = "sg-xxxxxxxxxxxxxxxxx"
}

variable "aws_vpc_subnet_id" {
  description = "サブネットの ID"
  type        = string
  # example = "subnet-xxxxxxxxxxxxxxxxx"
}

variable "aws_keepalived_instance_role_name" {
  description = "ルートテーブルの書き換えが可能なポリシーを持つロール"
  # example = "xxxxxxxxxx"
}

variable "aws_vpc_route_table_id_for_virtual_ips" {
  description = "仮想 IP を付与するルートテーブル"
  # example = "rtb-xxxxxxxxxxxxxxxxx"
}

variable "http_proxy_host" {
  description = "HTTP プロキシのホスト名/IP"
  # example = "xxx.xxx.xxx.xxx"
}

variable "http_proxy_port" {
  description = "HTTP プロキシのポート番号"
  default     = 3128
}

variable "keepalived_vrrp_network_interface" {
  description = "Keepalived の VRRP で利用する NIC の名前"
  default     = "eth0"
}

variable "ssh_user" {
  description = "SSH で利用するユーザー（設定する名前は AMI に依存）"
  default     = "centos"
}

variable "ssh_public_key" {
  description = "SSH 公開鍵のパス"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  description = "SSH 秘密鍵のパス"
  default     = "~/.ssh/id_rsa"
}

variable "name_prefix" {
  description = "リソースの命名に含めるプレフィックス。誰が作ったリソースか識別するのに利用する"
  # example = "lerna-user1"
}

variable "keepalived_instance_type" {
  description = "Keepalived サーバーのインスタンスタイプ"
  default     = "c5.large"
}

variable "haproxy_instance_type" {
  description = "HAProxy サーバーのインスタンスタイプ"
  default     = "c5.large"
}

variable "app_instance_type" {
  description = "アプリケーションサーバーのインスタンスタイプ"
  default     = "r5.large"
}

variable "cassandra_instance_type" {
  description = "Cassandra サーバーのインスタンスタイプ"
  default     = "r5.xlarge"
}

variable "mariadb_instance_type" {
  description = "MariaDB サーバーのインスタンスタイプ"
  default     = "r5.large"
}

variable "gatling_instance_type" {
  description = "Gatlingホストのインスタンスタイプ"
  default     = "r5.large"
}

variable "keepalived_volume_size_gb" {
  description = "Keepalived サーバーの ディスク容量"
  type        = number
  default     = 16
}

variable "haproxy_volume_size_gb" {
  description = "HAProxy サーバーのディスク容量（単位：GB）"
  type        = number
  default     = 16
}

variable "app_volume_size_gb" {
  description = "アプリケーションサーバーのディスク容量（単位：GB）"
  type        = number
  default     = 16
}

variable "cassandra_volume_size_gb" {
  description = "Cassandra サーバーのディスク容量（単位：GB）"
  type        = number
  default     = 64
}

variable "mariadb_volume_size_gb" {
  description = "MariaDB サーバーのディスク容量（単位：GB）"
  type        = number
  default     = 64
}

variable "gatling_volume_size_gb" {
  description = "Gatling サーバーのディスク容量（単位：GB）"
  type        = number
  default     = 64
}

variable "keepalived_private_ips" {
  description = "Keepalived サーバーの Private IP リスト"
  type        = list(string)
  # example = []
}

variable "haproxy_private_ips" {
  description = "HAProxy サーバーの Private IP リスト"
  type        = list(string)
  # example = []
}

variable "app_private_ips" {
  description = "Application サーバーの Private IP リスト"
  type        = list(string)
  # example = []
}

variable "cassandra_private_ips" {
  description = "Cassandra サーバーの Private IP リスト"
  type        = list(string)
  # example = []
}

variable "mariadb_private_ips" {
  description = "MariaDB サーバーの Private IP リスト"
  type        = list(string)
  # example = []
}

variable "gatling_private_ips" {
  description = "Gatling サーバーの Private IP リスト"
  type        = list(string)
  default     = []
}

variable "keepalived_virtual_ips" {
  type        = list(string)
  description = "Keepalived が付与する仮想 IP（サブネットの範囲外の IP を指定）"
  # example = ["192.168.100.100"]
}
