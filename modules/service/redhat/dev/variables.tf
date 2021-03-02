
variable "haproxy_ssh_hosts" {
  type        = list(string)
  description = "HAProxy の SSH 用ホストリスト（HAProxy のインストール先）"
  # example = ["10.10.10.2"]
}

variable "ssh_users" {
  type        = map(string)
  description = "ホストごとの SSH のユーザー"
  default     = null
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
