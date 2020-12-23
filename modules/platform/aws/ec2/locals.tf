locals {
  # 全インスタンスの IP
  instance_private_ips = concat(
    aws_instance.keepalived.*.private_ip,
    aws_instance.haproxy.*.private_ip,
    aws_instance.app.*.private_ip,
    aws_instance.cassandra.*.private_ip,
    aws_instance.mariadb.*.private_ip,
    aws_instance.gatling.*.private_ip,
  )

  # リージョン
  region = "ap-northeast-1"

  app_java_home = "/usr/lib/jvm/jre"

  cassandra_java_home = "/usr/lib/jvm/jre"
}
