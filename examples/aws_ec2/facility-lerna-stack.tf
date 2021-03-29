module "lerna_stack_service_redhat_dev" {
  source = "../../modules/service/redhat/dev"

  # [必須] HAProxy の SSH 用ホストリスト（HAProxy のインストール先）
  haproxy_ssh_hosts = module.lerna_stack_platform_aws_ec2.haproxy_instance_ips

  # ホストごとの SSH のユーザー
  ssh_users = zipmap(module.lerna_stack_platform_aws_ec2.haproxy_instance_ips, [for i in module.lerna_stack_platform_aws_ec2.haproxy_instance_ips : module.lerna_stack_platform_aws_ec2.ssh_user])

  # SSH 秘密鍵のパス
  ssh_private_key = module.lerna_stack_platform_aws_ec2.ssh_private_key

  # SSH のパスワード
  //ssh_passwords = null
}

module "lerna_stack_service_redhat_core" {
  source = "../../modules/service/redhat/core"

  # 有効にするテナント
  active_tenants = ["example"]

  # ホストごとの SSH のユーザー
  ssh_users = zipmap(local.all_instance_ips, [for i in local.all_instance_ips : module.lerna_stack_platform_aws_ec2.ssh_user])

  # SSH 公開鍵のパス
  ssh_public_key = module.lerna_stack_platform_aws_ec2.ssh_public_key

  # SSH 秘密鍵のパス
  ssh_private_key = module.lerna_stack_platform_aws_ec2.ssh_private_key

  # SSH のパスワード
  //ssh_passwords = null

  # sudo のパスワード認証を自動解決する。パスワード認証が有効な場合は必須
  //enable_sudo_askpass = false

  # [必須] Keepalived RPMファイルのパス
  keepalived_rpm_path = "${path.module}/resources/keepalived-2.0.16-1.x86_64.rpm"

  # [必須] Keepalived の SSH 用ホストリスト（Keepalived のインストール先）
  keepalived_ssh_hosts = module.lerna_stack_platform_aws_ec2.keepalived_instance_ips

  # [必須] Keepalived の内部通信用ホストリスト
  keepalived_cluster_hosts = module.lerna_stack_platform_aws_ec2.keepalived_instance_ips

  # [必須] Keepalived の仮想 IP
  keepalived_virtual_ips = { example = module.lerna_stack_platform_aws_ec2.keepalived_virtual_ips[0] }

  # [必須] Keepalived の仮想ルーター ID（0～255 の中から全体で重複がない ID を割り当てる必要がある）
  keepalived_virtual_router_ids = { example = 1 }

  # Keepalived の仮想IP用のネットワークインターフェース
  keepalived_virtual_ip_interface = module.lerna_stack_platform_aws_ec2.keepalived_virtual_ip_interface

  # Keepalived の LVS Sync Daemon 用のネットワークインターフェース
  keepalived_lvs_sync_daemon_interface = module.lerna_stack_platform_aws_ec2.keepalived_virtual_ip_interface

  # [必須] HAProxy の SSH 用ホストリスト（HAProxy のインストール先）
  haproxy_ssh_hosts = module.lerna_stack_platform_aws_ec2.haproxy_instance_ips

  # [必須] HAProxy の内部通信用ホストリスト
  haproxy_cluster_hosts = { example = module.lerna_stack_platform_aws_ec2.haproxy_instance_ips }

  # [必須] HAProxy RPMファイルのパス
  haproxy_rpm_path = "${path.module}/resources/haproxy-2.0.13-1.x86_64.rpm"

  # [必須] HAProxy がテナントごとに受け付けを許可する TPS 数。このレートを超えた場合 HTTP ステータス 503 がクライアントに返される
  haproxy_rate_limit_tps = { example = 10 }

  # [必須] HAProxy がテナントごとに受け付ける最大コネクション数。
  haproxy_max_connection = { example = 300 }

  # [必須] HAProxy がテナントごとにアプリケーション 1 プロセスへ接続する最大コネクション数。アプリケーション 1 プロセスから見ると確立されるコネクション数は [テナント数 ✕ HAProxy のノード数 ✕ 最大コネクション数] になる
  haproxy_to_app_max_connection = { example = 5 }

  # HAProxy の SSL 通信で利用するクライアント証明書発行元 CA の証明書のサーバー上のパス。事前にサーバー上にファイルが配置されている必要がある
  //haproxy_ca_file_path = "/usr/local/certs/CA.crt"

  # [必須] HAProxy の SSL 通信で利用する SSL 証明書のサーバー上のパス。事前にサーバー上にファイルが配置されている必要がある
  haproxy_crt_file_path = { example = module.lerna_stack_service_redhat_dev.haproxy_crt_file_path }

  # [必須] Application RPM ファイルの絶対パス
  app_rpm_path = var.app_rpm_path

  # [必須] アプリケーションの起動に利用する JAVA_HOME
  app_java_home = module.lerna_stack_platform_aws_ec2.app_java_home

  # [必須] アプリのサービス名
  app_service_name = "lerna-sample-payment-app"

  # [必須] アプリのサービスで使用されるユーザー名
  app_service_user = "payment-app"

  # [必須] Application のホストリスト
  app_ssh_hosts = module.lerna_stack_platform_aws_ec2.app_instance_ips

  # [必須] Application のクラスタホストリスト
  app_cluster_hosts = module.lerna_stack_platform_aws_ec2.app_instance_ips

  # [必須] Application が業務処理のリクエストを受け付けるポート
  app_service_port = 9001

  # [必須] Application がヘルスチェックのリクエストを受け付けるポート
  app_health_check_port = 9002

  # [必須] Application が Akka Cluster 間の通信に利用するポート
  app_akka_cluster_port = 25520

  # Akka の ActorSystem に設定した名前
  app_akka_actor_system_name = "GatewaySystem"

  # [必須] Application の JMX ポート番号
  app_jmx_port = 8686

  # アプリから外部システムへのリクエストで SSL のホスト名検証を無効化する。スタブを利用する際に有効化
  //app_disable_ssl_hostname_verification = false

  # [必須] アプリのヘルスチェックに使うパス
  app_health_check_path = "/health"

  # RPM がアプリをインストールする場所。デフォルトは sbt-native-packager デフォルトのインストールロケーション。https://sbt-native-packager.readthedocs.io/en/latest/archetypes/cheatsheet.html?highlight=defaultlinuxinstalllocation#settings
  app_install_dir = "/apl"

  # アプリのヒープダンプや JVM の致命的エラーログファイルをダンプする場所。デフォルトは sbt-native-packager デフォルトのログディレクトリ。https://sbt-native-packager.readthedocs.io/en/latest/archetypes/cheatsheet.html?highlight=defaultLinuxLogsLocation#settings
  app_dump_dir = "/apl/var/log"

  # アプリ停止のタイムアウト値
  //app_stop_timeout_sec = "5min"

  # プロジェクト特有のアプリケーションの起動引数。リストの index は app_cluster_hosts と対応し、設定が app_cluster_hosts と対応する各サーバーに配置されます
  app_arguments = data.template_file.app_arguments.*.rendered

  # [必須] プロジェクト特有のアプリケーションの設定。リストの index は app_cluster_hosts と対応し、設定が app_cluster_hosts と対応する各サーバーに配置されます
  app_configs = data.template_file.app_config.*.rendered

  # [必須] Cassandra RPMファイルのパス
  cassandra_rpm_path = "${path.module}/resources/cassandra-3.11.4-1.noarch.rpm"

  # [必須] Cassandra の起動に利用する JAVA_HOME
  cassandra_java_home = module.lerna_stack_platform_aws_ec2.cassandra_java_home

  # [必須] Cassandra の SSH 用ホストリスト（Cassandra のインストール先）
  cassandra_ssh_hosts = module.lerna_stack_platform_aws_ec2.cassandra_instance_ips

  # [必須] Cassandra のクラスタ間通信用ホストリスト
  cassandra_cluster_hosts = module.lerna_stack_platform_aws_ec2.cassandra_instance_ips

  # [必須] Cassandra の内部接続受付用ホストリスト
  cassandra_service_hosts = module.lerna_stack_platform_aws_ec2.cassandra_instance_ips

  # Cassandra の local DC のうち、seed にするノードの IP を指定
  cassandra_seed_private_ips = [module.lerna_stack_platform_aws_ec2.cassandra_instance_ips[0]]

  # [必須] Cassandra の DC リスト
  cassandra_data_center_ids = ["dc0"]

  # [必須] この面で利用する Cassandra の DC を指定
  cassandra_local_data_center_id = "dc0"

  # [必須] Cassandra のノードを可用性ゾーンにグルーピングする。ノードの指定には cassandra_ssh_hosts の値を使用してください
  cassandra_availability_zones = { az1 = module.lerna_stack_platform_aws_ec2.cassandra_instance_ips }

  # [必須] Cassandra のテナントごとのキースペース
  cassandra_keyspaces = { example = ["akka_example"] }

  # MariaDBのyumリポジトリに使用するディストリビューション名
  mariadb_yum_repository_distribution_name = "centos8"

  # [必須] MariaDB の SSH 用ホストリスト（MariaDB のインストール先）
  mariadb_ssh_hosts = module.lerna_stack_platform_aws_ec2.mariadb_instance_ips

  # [必須] MariaDB のクラスタ間通信用ホストリスト
  mariadb_cluster_hosts = module.lerna_stack_platform_aws_ec2.mariadb_instance_ips
}

data "template_file" "app_arguments" {
  count    = length(module.lerna_stack_platform_aws_ec2.app_instance_ips)
  template = <<-EOL

  #
  # lerna-sample-payment-app
  #

  ### Basics
  -Dakka.cluster.min-nr-of-members=1
  -Dakka.remote.artery.canonical.hostname=${module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]}
  -Dkamon.environment.host=${module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]}
  -Dkamon.system-metrics.host.sigar-native-folder=native/1
  -Dreactive.logs_dir=/apl/var/log/lerna-sample-payment-app
  -Djp.co.tis.lerna.payment.server-mode=PRODUCTION
  -Dlerna.util.encryption.base64-key=v5LCFG4V1CbJxxPg+WTd8w==
  -Dlerna.util.encryption.base64-iv=46A7peszgqN3q/ww4k8lWg==
  -Dpublic-internet.http.interface=${module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]}
  -Dprivate-internet.http.interface=${module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]}
  -Dmanagement.http.interface=${module.lerna_stack_platform_aws_ec2.app_instance_ips[count.index]}

  ### Cassandra
  -Djp.co.tis.lerna.payment.application.persistence.cassandra.default.events-by-tag.first-time-bucket=20191030T10:30
  -Dlerna.util.sequence.cassandra.default.contact-points=[]
  %{for cassandra_instance_ip in module.lerna_stack_platform_aws_ec2.cassandra_instance_ips}
  -Dlerna.util.sequence.cassandra.default.contact-points.${index(module.lerna_stack_platform_aws_ec2.cassandra_instance_ips, cassandra_instance_ip)}=${cassandra_instance_ip}
  %{endfor}
  -Dlerna.util.sequence.cassandra.default.data-center-replication-factors=[]
  -Dlerna.util.sequence.cassandra.default.data-center-replication-factors.0=dc0:1

  ### RDBMS
  -Djp.co.tis.lerna.payment.readmodel.rdbms.default.db.url=jdbc:mysql://${module.lerna_stack_platform_aws_ec2.mariadb_instance_ips[0]}:3306/PAYMENTAPP
  -Djp.co.tis.lerna.payment.readmodel.rdbms.default.db.user=paymentapp
  -Djp.co.tis.lerna.payment.readmodel.rdbms.default.db.password=password

  ### External Services
  -Djp.co.tis.lerna.payment.gateway.issuing.default.base-url=http://127.0.0.1:8083
  -Djp.co.tis.lerna.payment.gateway.wallet-system.default.base-url=http://127.0.0.1:8083

  ### Tenants
  -Djp.co.tis.lerna.payment.presentation.util.api.tenants.example.IssuingService.active=on

  EOL
}

data "template_file" "app_config" {
  count    = length(module.lerna_stack_platform_aws_ec2.app_instance_ips)
  template = <<-EOL
  EOL
}
