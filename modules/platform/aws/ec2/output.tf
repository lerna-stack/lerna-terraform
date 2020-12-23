output "ssh_user" {
  value = var.ssh_user
}

output "ssh_public_key" {
  value = var.ssh_public_key
}

output "ssh_private_key" {
  value = var.ssh_private_key
}

output "http_proxy_host" {
  value = var.http_proxy_host
}

output "http_proxy_port" {
  value = var.http_proxy_port
}

output "keepalived_virtual_ips" {
  value = var.keepalived_virtual_ips
}

output "keepalived_virtual_ip_interface" {
  value = var.keepalived_vrrp_network_interface
}

output "keepalived_instance_ips" {
  value = aws_instance.keepalived.*.private_ip
  depends_on = [
    # 最初に HTTP Proxy の設定をしたり、セットアップの再実行を容易にするため初期セットアップ部分を null_resource に切り出している
    # 初期セットアップが完了した状態で他のモジュールがインスタンスを利用できるようにするため、依存関係を定義
    null_resource.setup_for_keepalived
  ]
}

output "haproxy_instance_ips" {
  value = aws_instance.haproxy.*.private_ip
  depends_on = [
    # 最初に HTTP Proxy の設定をしたり、セットアップの再実行を容易にするため初期セットアップ部分を null_resource に切り出している
    # 初期セットアップが完了した状態で他のモジュールがインスタンスを利用できるようにするため、依存関係を定義
    null_resource.setup_for_haproxy
  ]
}

output "app_instance_ips" {
  value = aws_instance.app.*.private_ip
  depends_on = [
    # 最初に HTTP Proxy の設定をしたり、セットアップの再実行を容易にするため初期セットアップ部分を null_resource に切り出している
    # 初期セットアップが完了した状態で他のモジュールがインスタンスを利用できるようにするため、依存関係を定義
    null_resource.setup_for_app
  ]
}

output "cassandra_instance_ips" {
  value = aws_instance.cassandra.*.private_ip
  depends_on = [
    # 最初に HTTP Proxy の設定をしたり、セットアップの再実行を容易にするため初期セットアップ部分を null_resource に切り出している
    # 初期セットアップが完了した状態で他のモジュールがインスタンスを利用できるようにするため、依存関係を定義
    null_resource.setup_for_cassandra
  ]
}

output "mariadb_instance_ips" {
  value = aws_instance.mariadb.*.private_ip
  depends_on = [
    # 最初に HTTP Proxy の設定をしたり、セットアップの再実行を容易にするため初期セットアップ部分を null_resource に切り出している
    # 初期セットアップが完了した状態で他のモジュールがインスタンスを利用できるようにするため、依存関係を定義
    null_resource.setup_for_mariadb
  ]
}

output "gatling_instance_ips" {
  value = aws_instance.gatling.*.private_ip
  depends_on = [
    # 最初に HTTP Proxy の設定をしたり、セットアップの再実行を容易にするため初期セットアップ部分を null_resource に切り出している
    # 初期セットアップが完了した状態で他のモジュールがインスタンスを利用できるようにするため、依存関係を定義
    null_resource.setup_for_gatling
  ]
}

output "app_java_home" {
  value = local.app_java_home
}

output "cassandra_java_home" {
  value = local.cassandra_java_home
}
