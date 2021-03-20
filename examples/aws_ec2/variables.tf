variable "aws_access_key" {
  description = "AWS アクセスキー ID"
  # example = "AKIAxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "aws_secret_key" {
  description = "AWS アクセスキー Secret"
  # example = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "name_prefix" {
  description = "リソースの命名に含めるプレフィックス。誰が作ったリソースか識別するのに利用する"
  # example = "lerna-user1"
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

variable "ssh_user" {
  description = "ssh ユーザ"
  default     = "centos"
}

variable "ssh_public_key_file_path" {
  description = "SSH 公開鍵 のファイルパス"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_file_path" {
  description = "SSH 秘密鍵 のファイルパス"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "app_rpm_path" {
  description = "アプリケーションの RPM ファイルの絶対パス"
  default     = "./resources/lerna-sample-payment-app-1.0.0-1.noarch.rpm"
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

variable "cassandra_backup_user_ssh_public_key_filepath" {
  description = "Cassandraバックアップジョブ用ユーザが使用する SSH 公開鍵 のファイルパス"
  type        = string
  default     = "./resources/id_rsa_cassandra_backup_user.pub"
}

variable "cassandra_backup_user_ssh_private_key_filepath" {
  description = "Cassandraバックアップジョブ用ユーザが使用する SSH 秘密鍵 のファイルパス。※この秘密鍵は、Cassandra サーバに配布され、開発チームで共有されます。専用の鍵を新規に作成することを強く推奨します。"
  type        = string
  default     = "./resources/id_rsa_cassandra_backup_user"
}

variable "nfs_instance_private_ip" {
  description = "NFS サーバの Private IP"
  type        = string
  # example = "10.0.0.1"
}
