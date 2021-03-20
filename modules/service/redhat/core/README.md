# `service/redhat/core`

既存のサーバー上に Lerna Stack の各種サービス（Keepalived, Cassandra など）とアプリケーションをデプロイします。

## Inputs
🚧 WIP

### アプリケーション

🚧 WIP

#### `app_stop_timeout_sec (default = "5min")`

アプリ停止のタイムアウト値です。  
このタイムアウトを経過してもアプリが停止しない場合には、SIGKILLによりアプリを強制停止します。  
設定値のフォーマットは [systemd.time] が使えます。`infinity` でタイムアウトを無効化できます。  
アプリケーションのグレースフルシャットダウンにかかる時間よりも長く設定することを推奨します。  
ほとんどの場合にはデフォルト値で十分ですが、デフォルト値よりも長くなる見込みがある場合には調整する必要があります。


## Outputs

🚧 WIP


[systemd.time]: https://www.freedesktop.org/software/systemd/man/systemd.time.html
