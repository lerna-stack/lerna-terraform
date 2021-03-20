# Cassandra バックアップ

Cassandra のデータバックアップを取得できます。  
バックアップは スクリプト `/opt/management/bin/APP_cassandra_backup.sh` を用いて取得します。  
バックアップはテナントごとに取得します。
[redhat/core] の `cassandra_keyspaces` に設定したテナント名とキースペースから、
テナントごとのキースペースが解決され、そのキースペースがバックアップされます。

## 前提条件

- バックアップは Cassandra サーバ の `/apl/cassandra_backup` に作成されます。
- バックアップスクリプトは `/apl/cassandra_backup` が何かのデバイスにマウントされることを想定しています。  
  Cassandraサーバの `/etc/fstab` に `/apl/cassandra_backup` 向けのエントリを追加してください。  
  マウントオプションには `noauto`, `user` を指定してください。  
  バックアップスクリプトは、バックアップ取得時のみこのデバイスをマウントします。
- ユーザ `reactivejob` を手動で作成しておく必要があります。
- `/opt/management/bin/APP_cassandra_backup_kick.sh` にバックアップ対象の Cassandra サーバの IP アドレスが変数(`PROD_HOSTS`, `DR_HOSTS`) にハードコードされています。  
  バックアップスクリプトを起動する Cassandra サーバにインストールされている `/opt/management/bin/APP_cassandra_backup_kick.sh` の変数を手動で書き換える必要があります。
- 1つのCassandraノードのみをバックアップ対象とします。  
  Cassandra クラスタに参加しているすべてのノードにデータがレプリケーションされていることを想定しています。  
  キースペースの レプリケーションファクタ が Cassandra クラスタのノード数よりも小さい場合はサポートしていません。
- `/apl/cassandra_backup` に最大で4世代分(最新1世代＋過去3世代)のログを残すようになっています。  
  ログファイル肥大化防止のため、バックアップスクリプトは5世代以上のログが存在する場合、  
  新しい4世代分のみを残すようにそれ以外のログ以外を削除します。  
  もしもすべての過去のログを残したい場合には、古いバックアップファイルを別の場所に退避するようにしてください。  


## バックアップ方法

Cassandra サーバに ssh で接続し、`/opt/management/bin/APP_cassandra_backup.sh` を実行します。  
ssh で接続するユーザは `reactivejob` を使用してください。
`reactivejob`とは異なるユーザを使用することはサポートされていません。

バックアップを実行するには、次のコマンドを実行します。    
このコマンドでは、 [redhat/core] の `cassandra_keyspaces` に テナント `example` を設定しており、
`example` に関連付けられた キースペース のバックアップを取得する例を示しています。  

※`host="10.0.1.61"` は、CassandraサーバのIPアドレスに適切に置換してください。  
※`example` は取得するテナント名に適切に変更してください。

```shell
$ host="10.0.1.61"
$ ssh reactivejob@${host} nohup /opt/management/bin/APP_cassandra_backup.sh example
# (... truncated)
2021/03/17 02:56:07     APP_cassandra_backup.sh reactivejob     exit_code:0     INFO    Cassandra backup tenant id : example is success.
```

バックアップが完了すると、`/apl/cassandra_back` にマウントされるデバイスにバックアップファイルが作成されています。  
バックアップファイルの名前は、`cassandra_{tenant}_{datetime}.tar.gz` となっています。  
取得したバックアップファイル一覧は次のように確認できます。  

```shell
$ ssh reactivejob@10.0.1.61
[reactivejob@10.0.1.61]$ mount /apl/cassandra_backup 
[reactivejob@10.0.1.61]$ ls -l /apl/cassandra_backup 
total 4
-rw-rw-r--. 1 reactivejob reactivejob 1828 Mar 17 03:15 cassandra_example_20210317_031522.tar.gz
[reactivejob@10.0.1.61]$ umount /apl/cassandra_backup
```


## ユーザ `reactivejob` に求められる要件

- すべての Cassandra サーバに ユーザ`reactivejob` が作成されていること
- バックアップスクリプトを起動する Cassandra サーバから、すべての Cassandra サーバ に ユーザ `reactivejob` で ssh 接続できること
- `reactivejob` は グループ `lv4`, `lv5` に所属していること


## サンプル
サンプルプロジェクト[examples/aws_ec2]で Cassandra バックアップを動作確認することができます。  
サンプルプロジェクトでは、[facility-cassandra-backup.tf] にて、ユーザ `reactivejob` の作成やバックアップデバイスとして使用する NFS サーバの作成&設定を実施しています。

※サンプルは、バックアップスクリプトが動作する要件を満たすことのみを例示するものとなっています。
セキュリティや可用性について十分に考慮されていないため、 **サンプルコードを PRODUCTION で使用しないでください。**



[redhat/core]: /modules/service/redhat/core
[examples/aws_ec2]: /examples/aws_ec2
[facility-cassandra-backup.tf]: /examples/aws_ec2/facility-cassandra-backup.tf
