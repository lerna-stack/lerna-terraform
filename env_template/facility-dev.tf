module "dev" {
  source = "../modules/service/centos/dev"

  # [必須] HAProxy の SSH 用ホストリスト（HAProxy のインストール先）
  //haproxy_ssh_hosts = ["10.10.10.2"]

  # ホストごとの SSH のユーザー
  //ssh_users = null

  # SSH 秘密鍵のパス
  //ssh_private_key = "~/.ssh/id_rsa"

  # SSH のパスワード
  //ssh_passwords = null
}
