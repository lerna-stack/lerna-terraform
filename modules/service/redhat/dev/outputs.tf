output "haproxy_crt_file_path" {
  value       = local.haproxy_crt_file_path
  description = "HAProxy サーバーにインストールする SSL 証明書のパス。SSL 通信で利用"
}
