# Jump Instance Module

セキュアに ssh 接続できる踏み台インスタンス (別名 jump server) を構築します。  
AWS Systems Manager を使うため、sshポートをインターネットに公開する必要はありません。

## 接続方法
このインスタンスに接続するためには次の手順を実施します。

### ローカルマシンのsshを設定する

ローカルマシンのsshの設定ファイルに AWS Session Manager を通して SSH接続するための設定項目を追加します。  
詳細は、[ステップ 8: (オプション) Session Manager を通して SSH 接続を有効にする](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-getting-started-enable-ssh-connections.html)
を参照してください。

ローカルマシンが Windows の場合、次のような項目をsshの設定ファイルに追加します。
```conf
# SSH over Session Manager
host i-* mi-*
  ProxyCommand powershell "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p"
```
sshの設定ファイルは、通常は `~/.ssh/config` にあります。

### 2. sshセッションを確立する

`ssh` コマンドで sshセッションを確立できます。

```shell
ssh -i /path/private-key username@instance-id
```

※ `/path/private-key`, `username`, `instance-id` は作成したインスタンスに対応して置き換える必要があります。

また、 `scp` コマンド を使いファイルを転送することもできます。

```shell
# /path/SampleFile.txt を 転送します。
scp -i /path/private-key /path/SampleFile.txt username@instance-id:~
```

詳しくは、[セッションを開始する](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-start-ssh) を参照してください。

## FAQ

### `SessionManagerPlugin is not found` と表示される

ssh で接続しようとすると次のようなエラーがでる場合は、ローカルに SessionManagerPlugin がインストールされていません。

```
SessionManagerPlugin is not found. Please refer to SessionManager Documentation here: http://docs.aws.amazon.com/console/systems-manager/session-manager-plugin-not-found
```

次のドキュメントを参考にして SessionManagerPlugin をインストールしてください。

- https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows
- https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-troubleshooting.html#plugin-not-found

## 参考文献

- [General prerequisites for connecting to your instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connection-prereqs.html#connection-prereqs-get-info-about-instance)
