# `service/redhat/core`

既存のサーバー上に Lerna Stack の各種サービス（Keepalived, Cassandra など）とアプリケーションをデプロイします。

## Inputs
🚧 WIP

### アプリケーション

🚧 WIP

#### `app_stop_timeout_sec (default = "5s")`

アプリ停止のタイムアウト値です。  
このタイムアウトを経過してもアプリが停止しない場合には、SIGKILLによりアプリを強制停止します。  
設定値のフォーマットは [systemd.time] が使えます。  
`infinity` でタイムアウトを無効化できます。


## Outputs

🚧 WIP


[systemd.time]: https://www.freedesktop.org/software/systemd/man/systemd.time.html
