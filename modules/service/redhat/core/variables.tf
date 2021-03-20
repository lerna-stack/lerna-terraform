
variable "active_tenants" {
  type        = list(string)
  description = "有効にするテナント"
  default     = ["default"]
}

variable "ssh_users" {
  type        = map(string)
  description = "ホストごとの SSH のユーザー"
  default     = null
}

variable "ssh_public_key" {
  type        = string
  description = "SSH 公開鍵のパス"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  type        = string
  description = "SSH 秘密鍵のパス"
  default     = "~/.ssh/id_rsa"
}

variable "ssh_passwords" {
  type        = map(string)
  description = "SSH のパスワード"
  default     = null
}

variable "enable_sudo_askpass" {
  type        = bool
  description = "sudo のパスワード認証を自動解決する。パスワード認証が有効な場合は必須"
  default     = false
}

variable "keepalived_rpm_path" {
  type        = string
  description = "Keepalived RPMファイルのパス"
  # example = "${path.module}/resources/keepalived-2.0.16-1.x86_64.rpm"
}

variable "keepalived_ssh_hosts" {
  type        = list(string)
  description = "Keepalived の SSH 用ホストリスト（Keepalived のインストール先）"
  # example = ["10.10.10.1"]
}

variable "keepalived_cluster_hosts" {
  type        = list(string)
  description = "Keepalived の内部通信用ホストリスト"
  # example = ["192.168.50.1"]
}

variable "keepalived_virtual_ips" {
  type        = map(string)
  description = "Keepalived の仮想 IP"
  # example = { default = "192.168.100.1" }
}

variable "keepalived_virtual_router_ids" {
  type        = map(number)
  description = "Keepalived の仮想ルーター ID（0～255 の中から全体で重複がない ID を割り当てる必要がある）"
  # example = { default = 0 }
}

variable "keepalived_virtual_ip_interface" {
  type        = string
  description = "Keepalived の仮想IP用のネットワークインターフェース"
  default     = "eth0"
}

variable "keepalived_lvs_sync_daemon_interface" {
  type        = string
  description = "Keepalived の LVS Sync Daemon 用のネットワークインターフェース"
  default     = "eth0"
}

variable "haproxy_ssh_hosts" {
  type        = list(string)
  description = "HAProxy の SSH 用ホストリスト（HAProxy のインストール先）"
  # example = ["10.10.10.2"]
}

variable "haproxy_cluster_hosts" {
  type        = map(list(string))
  description = "HAProxy の内部通信用ホストリスト"
  # example = { default = ["192.168.50.2"] }
}

variable "haproxy_rpm_path" {
  type        = string
  description = "HAProxy RPMファイルのパス"
  # example = "${path.module}/resources/haproxy-2.0.13-1.x86_64.rpm"
}

variable "haproxy_rate_limit_tps" {
  type        = map(number)
  description = "HAProxy がテナントごとに受け付けを許可する TPS 数。このレートを超えた場合 HTTP ステータス 503 がクライアントに返される"
  # example = { default = 10 }
}

variable "haproxy_max_connection" {
  type        = map(number)
  description = "HAProxy がテナントごとに受け付ける最大コネクション数。"
  # example = { default = 300 }
}

variable "haproxy_to_app_max_connection" {
  type        = map(number)
  description = "HAProxy がテナントごとにアプリケーション 1 プロセスへ接続する最大コネクション数。アプリケーション 1 プロセスから見ると確立されるコネクション数は [テナント数 ✕ HAProxy のノード数 ✕ 最大コネクション数] になる"
  # example = { default = 5 }
}

variable "haproxy_ca_file_path" {
  type        = string
  description = "HAProxy の SSL 通信で利用するクライアント証明書発行元 CA の証明書のサーバー上のパス。事前にサーバー上にファイルが配置されている必要がある"
  default     = ""
  # example = "/usr/local/certs/CA.crt"
}

variable "haproxy_crt_file_path" {
  type        = map(string)
  description = "HAProxy の SSL 通信で利用する SSL 証明書のサーバー上のパス。事前にサーバー上にファイルが配置されている必要がある"
  # example = { default = "/usr/local/certs/example.com.pem" }
}

variable "app_rpm_path" {
  type        = string
  description = "Application RPM ファイルの絶対パス"
  # example = "/path/to/rpm/example-app-0.1.0-1.noarch.rpm"
}

variable "app_java_home" {
  type        = string
  description = "アプリケーションの起動に利用する JAVA_HOME"
  # example = "/usr/lib/jvm/java-8-openjdk-amd64/jre"
}

variable "app_service_name" {
  type        = string
  description = "アプリのサービス名"
  # example = "example-app"
}

variable "app_service_user" {
  type        = string
  description = "アプリのサービスで使用されるユーザー名"
  # example = "example-user"
}

variable "app_ssh_hosts" {
  type        = list(string)
  description = "Application のホストリスト"
  # example = ["10.10.10.3"]
}

variable "app_cluster_hosts" {
  type        = list(string)
  description = "Application のクラスタホストリスト"
  # example = ["192.168.50.3"]
}

variable "app_service_port" {
  type        = number
  description = "Application が業務処理のリクエストを受け付けるポート"
  # example = 9000
}

variable "app_health_check_port" {
  type        = number
  description = "Application がヘルスチェックのリクエストを受け付けるポート"
  # example = 9002
}

variable "app_akka_cluster_port" {
  type        = number
  description = "Application が Akka Cluster 間の通信に利用するポート"
  # example = 25520
}

variable "app_akka_actor_system_name" {
  type        = string
  description = "Akka の ActorSystem に設定した名前"
  default     = "default"
}

variable "app_jmx_port" {
  type        = number
  description = "Application の JMX ポート番号"
  # example = 8686
}

variable "app_disable_ssl_hostname_verification" {
  type        = bool
  description = "アプリから外部システムへのリクエストで SSL のホスト名検証を無効化する。スタブを利用する際に有効化"
  default     = false
}

variable "app_health_check_path" {
  type        = string
  description = "アプリのヘルスチェックに使うパス"
  # example = "/health"
}

variable "app_install_dir" {
  type        = string
  description = "RPM がアプリをインストールする場所。デフォルトは sbt-native-packager デフォルトのインストールロケーション。https://sbt-native-packager.readthedocs.io/en/latest/archetypes/cheatsheet.html?highlight=defaultlinuxinstalllocation#settings"
  default     = "/usr/share"
}

variable "app_dump_dir" {
  type        = string
  description = "アプリのヒープダンプや JVM の致命的エラーログファイルをダンプする場所。デフォルトは sbt-native-packager デフォルトのログディレクトリ。https://sbt-native-packager.readthedocs.io/en/latest/archetypes/cheatsheet.html?highlight=defaultLinuxLogsLocation#settings"
  default     = "/var/log"
}

variable "app_stop_timeout_sec" {
  type        = string
  description = "アプリ停止のタイムアウト値"
  default     = "5s"
}

variable "app_arguments" {
  type        = list(string)
  description = "プロジェクト特有のアプリケーションの起動引数。リストの index は app_cluster_hosts と対応し、設定が app_cluster_hosts と対応する各サーバーに配置されます"
  default     = null
  # example = []
}

variable "app_configs" {
  type        = list(string)
  description = "プロジェクト特有のアプリケーションの設定。リストの index は app_cluster_hosts と対応し、設定が app_cluster_hosts と対応する各サーバーに配置されます"
  # example = []
}

variable "cassandra_rpm_path" {
  type        = string
  description = "Cassandra RPMファイルのパス"
  # example = "${path.module}/resources/cassandra-3.11.4-1.noarch.rpm"
}

variable "cassandra_java_home" {
  type        = string
  description = "Cassandra の起動に利用する JAVA_HOME"
  # example = "/usr/lib/jvm/java-8-openjdk-amd64/jre"
}

variable "cassandra_ssh_hosts" {
  type        = list(string)
  description = "Cassandra の SSH 用ホストリスト（Cassandra のインストール先）"
  # example = []
}

variable "cassandra_cluster_hosts" {
  type        = list(string)
  description = "Cassandra のクラスタ間通信用ホストリスト"
  # example = []
}

variable "cassandra_service_hosts" {
  type        = list(string)
  description = "Cassandra の内部接続受付用ホストリスト"
  # example = []
}

variable "cassandra_seed_private_ips" {
  description = "Cassandra の local DC のうち、seed にするノードの IP を指定"
  type        = list(string)
  default     = []
}

variable "cassandra_data_center_ids" {
  type        = list(string)
  description = "Cassandra の DC リスト"
  # example = ["dc0"]
}

variable "cassandra_local_data_center_id" {
  type        = string
  description = "この面で利用する Cassandra の DC を指定"
  # example = "dc0"
}

variable "cassandra_availability_zones" {
  type        = map(list(string))
  description = "Cassandra のノードを可用性ゾーンにグルーピングする。ノードの指定には cassandra_ssh_hosts の値を使用してください"
  # example = { az1 = ["192.168.10.1", "192.168.10.2"], az2 = ["192.168.20.1", "192.168.20.2"]  }
}

variable "cassandra_keyspaces" {
  type        = map(list(string))
  description = "Cassandra のテナントごとのキースペース"
  # example = { default = ["akka"] }
}

variable "mariadb_yum_repository_distribution_name" {
  type        = string
  description = "MariaDBのyumリポジトリに使うディストリビューション名"
  default     = "centos8"
  validation {
    condition     = contains(["centos8", "rhel7"], var.mariadb_yum_repository_distribution_name)
    error_message = "Distribution Name must be 'centos8' or 'rhel7'."
  }
}

variable "mariadb_ssh_hosts" {
  type        = list(string)
  description = "MariaDB の SSH 用ホストリスト（MariaDB のインストール先）"
  # example = []
}

variable "mariadb_cluster_hosts" {
  type        = list(string)
  description = "MariaDB のクラスタ間通信用ホストリスト"
  # example = []
}
