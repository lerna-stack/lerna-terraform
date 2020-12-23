module "core" {
  source = "github.com/lerna-stack/lerna-terraform//modules/service/centos/core?ref=v1.0.0"

  # 有効にするテナント
  //active_tenants = ["default"]

  # ホストごとの SSH のユーザー
  //ssh_users = null

  # SSH 公開鍵のパス
  //ssh_public_key = "~/.ssh/id_rsa.pub"

  # SSH 秘密鍵のパス
  //ssh_private_key = "~/.ssh/id_rsa"

  # SSH のパスワード
  //ssh_passwords = null

  # sudo のパスワード認証を自動解決する。パスワード認証が有効な場合は必須
  //enable_sudo_askpass = false

  # [必須] Keepalived RPMファイルのパス
  //keepalived_rpm_path = "${path.module}/resources/keepalived-2.0.16-1.x86_64.rpm"

  # [必須] Keepalived の SSH 用ホストリスト（Keepalived のインストール先）
  //keepalived_ssh_hosts = ["10.10.10.1"]

  # [必須] Keepalived の内部通信用ホストリスト
  //keepalived_cluster_hosts = ["192.168.50.1"]

  # [必須] Keepalived の仮想 IP
  //keepalived_virtual_ips = { default = "192.168.100.1" }

  # [必須] Keepalived の仮想ルーター ID（0～255 の中から全体で重複がない ID を割り当てる必要がある）
  //keepalived_virtual_router_ids = { default = 0 }

  # Keepalived の仮想IP用のネットワークインターフェース
  //keepalived_virtual_ip_interface = "eth0"

  # Keepalived の LVS Sync Daemon 用のネットワークインターフェース
  //keepalived_lvs_sync_daemon_interface = "eth0"

  # [必須] HAProxy の SSH 用ホストリスト（HAProxy のインストール先）
  //haproxy_ssh_hosts = ["10.10.10.2"]

  # [必須] HAProxy の内部通信用ホストリスト
  //haproxy_cluster_hosts = { default = ["192.168.50.2"] }

  # [必須] HAProxy RPMファイルのパス
  //haproxy_rpm_path = "${path.module}/resources/haproxy-2.0.13-1.x86_64.rpm"

  # [必須] HAProxy がテナントごとに受け付けを許可する TPS 数。このレートを超えた場合 HTTP ステータス 503 がクライアントに返される
  //haproxy_rate_limit_tps = { default = 10 }

  # [必須] HAProxy がテナントごとに受け付ける最大コネクション数。
  //haproxy_max_connection = { default = 300 }

  # [必須] HAProxy がテナントごとにアプリケーション 1 プロセスへ接続する最大コネクション数。アプリケーション 1 プロセスから見ると確立されるコネクション数は [テナント数 ✕ HAProxy のノード数 ✕ 最大コネクション数] になる
  //haproxy_to_app_max_connection = { default = 5 }

  # HAProxy の SSL 通信で利用するクライアント証明書発行元 CA の証明書のサーバー上のパス。事前にサーバー上にファイルが配置されている必要がある
  //haproxy_ca_file_path = "/usr/local/certs/CA.crt"

  # [必須] HAProxy の SSL 通信で利用する SSL 証明書のサーバー上のパス。事前にサーバー上にファイルが配置されている必要がある
  //haproxy_crt_file_path = { default = "/usr/local/certs/example.com.pem" }

  # [必須] Application RPM ファイルの絶対パス
  //app_rpm_path = "/path/to/rpm/example-app-0.1.0-1.noarch.rpm"

  # [必須] アプリケーションの起動に利用する JAVA_HOME
  //app_java_home = "/usr/lib/jvm/java-8-openjdk-amd64/jre"

  # [必須] アプリのサービス名
  //app_service_name = "example-app"

  # [必須] アプリのサービスで使用されるユーザー名
  //app_service_user = "example-user"

  # [必須] Application のホストリスト
  //app_ssh_hosts = ["10.10.10.3"]

  # [必須] Application のクラスタホストリスト
  //app_cluster_hosts = ["192.168.50.3"]

  # [必須] Application が業務処理のリクエストを受け付けるポート
  //app_service_port = 9000

  # [必須] Application がヘルスチェックのリクエストを受け付けるポート
  //app_health_check_port = 9002

  # [必須] Application が Akka Cluster 間の通信に利用するポート
  //app_akka_cluster_port = 25520

  # Akka の ActorSystem に設定した名前
  //app_akka_actor_system_name = "default"

  # [必須] Application の JMX ポート番号
  //app_jmx_port = 8686

  # アプリから外部システムへのリクエストで SSL のホスト名検証を無効化する。スタブを利用する際に有効化
  //app_disable_ssl_hostname_verification = false

  # [必須] アプリのヘルスチェックに使うパス
  //app_health_check_path = "/health"

  # RPM がアプリをインストールする場所。デフォルトは sbt-native-packager デフォルトのインストールロケーション。https://sbt-native-packager.readthedocs.io/en/latest/archetypes/cheatsheet.html?highlight=defaultlinuxinstalllocation#settings
  //app_install_dir = "/usr/share"

  # アプリのヒープダンプや JVM の致命的エラーログファイルをダンプする場所。デフォルトは sbt-native-packager デフォルトのログディレクトリ。https://sbt-native-packager.readthedocs.io/en/latest/archetypes/cheatsheet.html?highlight=defaultLinuxLogsLocation#settings
  //app_dump_dir = "/var/log"

  # プロジェクト特有のアプリケーションの起動引数。リストの index は app_cluster_hosts と対応し、設定が app_cluster_hosts と対応する各サーバーに配置されます
  //app_arguments = []

  # [必須] プロジェクト特有のアプリケーションの設定。リストの index は app_cluster_hosts と対応し、設定が app_cluster_hosts と対応する各サーバーに配置されます
  //app_configs = []

  # [必須] Cassandra RPMファイルのパス
  //cassandra_rpm_path = "${path.module}/resources/cassandra-3.11.4-1.noarch.rpm"

  # [必須] Cassandra の起動に利用する JAVA_HOME
  //cassandra_java_home = "/usr/lib/jvm/java-8-openjdk-amd64/jre"

  # [必須] Cassandra の SSH 用ホストリスト（Cassandra のインストール先）
  //cassandra_ssh_hosts = []

  # [必須] Cassandra のクラスタ間通信用ホストリスト
  //cassandra_cluster_hosts = []

  # [必須] Cassandra の内部接続受付用ホストリスト
  //cassandra_service_hosts = []

  # Cassandra の local DC のうち、seed にするノードの IP を指定
  //cassandra_seed_private_ips = []

  # [必須] Cassandra の DC リスト
  //cassandra_data_center_ids = ["dc0"]

  # [必須] この面で利用する Cassandra の DC を指定
  //cassandra_local_data_center_id = "dc0"

  # [必須] Cassandra のノードを可用性ゾーンにグルーピングする。ノードの指定には cassandra_ssh_hosts の値を使用してください
  //cassandra_availability_zones = { az1 = ["192.168.10.1", "192.168.10.2"], az2 = ["192.168.20.1", "192.168.20.2"] }

  # [必須] Cassandra のテナントごとのキースペース
  //cassandra_keyspaces = { default = ["akka"] }

  # [必須] MariaDB の SSH 用ホストリスト（MariaDB のインストール先）
  //mariadb_ssh_hosts = []

  # [必須] MariaDB のクラスタ間通信用ホストリスト
  //mariadb_cluster_hosts = []
}
