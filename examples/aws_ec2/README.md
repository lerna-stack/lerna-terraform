# Example Lerna Stack 構築ガイド

既存の VPC に Lerna Stack の稼働環境を構築する方法を示します。

## 準備

### 1.デプロイ対象のアプリ/ミドルウェアの RPM を用意する

それぞれの RPM ファイルを [resources] ディレクトリに配置します

#### アプリ
Lerna のサンプルアプリ [lerna-sample-payment-app] の RPM ファイルをビルドしてください。  
ビルド手順は [RPMパッケージビルドガイド](https://github.com/lerna-stack/lerna-sample-payment-app/blob/main/docs/RPMパッケージビルドガイド.md) をご覧ください。  
作成された RPM ファイル`lerna-sample-payment-app-1.0.0-1.noarch.rpm`を [resources] に配置してください。  
※RPMファイルの名前が上記と異なる場合には、`terraform.tfvars` に記載されている `app_rpm_path` を作成された RPM ファイルパスとなるように書き換えてください。

#### ミドルウェア (Cassandra)
https://archive.apache.org/dist/cassandra/redhat/311x/ から `cassandra-3.11.4-1.noarch.rpm` をダウンロードしてください。  
ダウンロードした `cassandra-3.11.4-1.noarch.rpm` を [resources] に配置してください。

#### ミドルウェア (HAProxy)

OS のリポジトリにあるバージョンは古い場合があるため、独自にビルドを行います。

次の手順に従いビルドしてください。

[tools/rpmbuild/haproxy/README.md](../../tools/rpmbuild/haproxy/README.md)

作成された RPM ファイル `haproxy-2.0.13-1.x86_64.rpm` を [resources] に配置してください。

#### ミドルウェア (Keepalived)

OS のリポジトリにあるバージョンは古い場合があるため、独自にビルドを行います。

次の手順に従いビルドしてください。

[tools/rpmbuild/keepalived/README.md](../../tools/rpmbuild/keepalived/README.md)

作成された RPM ファイル `keepalived-2.0.16-1.x86_64.rpm` を [resources] に配置してください。

### 2. 環境設定

`terraform.tfvars.example` を同じディレクトリにコピーし、`terraform.tfvars` を作成します。

必要に応じて設定値のコメントアウトを解除し、設定します。

## 環境構築

下記のコマンドを実行します。

```bash
terraform apply
```

[各サービスの起動と再起動](../../docs/ops/各サービスの起動と再起動.md) を参考に、各サービスを起動します。  
アプリ(`lerna-sample-payment-app`) は後ほど起動するため、ここでは起動しないでください。

### MariaDB をセットアップする
※`terraform apply` 後に実施してください。  
MariaDB サービスを起動している必要があります。  
MariaDB サービスを起動するには [各サービスの起動と再起動](/docs/ops/各サービスの起動と再起動.md) をご確認ください。

MariaDB サーバで次の3つの作業を実施します。
- root ユーザを設定する
- データベースとアプリ用ユーザを作成する
- データベースにテーブルと初期データを作成する

※ MariaDB クラスタが複数台で構成されている場合でも、1台のサーバに対してのみ下記作業を実施します。
作業対象の MariaDB サーバは任意のものを選んで問題ありません。

#### root ユーザを設定する

デフォルトでは `root` ユーザのパスワードが設定されていないため、
パスワードを設定する必要があります。ここではパスワードとして`password`を設定します。  
※ PRODUCTION で利用する際には強固なパスワードを設定してください。
```shell
$ sudo mysqladmin -u root password 'password'
```

#### データベースとアプリ用ユーザを作成する

`root` ユーザでログインし、データベース`PAYMENTAPP`、アプリ用ユーザ`paymentapp`を作成します。

※ユーザ作成で使用している `paymentapp'@'10.0.1.0/255.255.255.0'` は、
デプロイする環境に合わせて変更してください。
ホスト名`10.0.1.0` と サブネットマスク `255.255.255.0` にアプリサーバのIPアドレスが含まれるようにする必要があります。
この例では、サブネット`10.0.1.0/24` に アプリサーバをデプロイした場合を想定しています。

```shell
$ mysql -u root -p'password'

Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 34
Server version: 10.5.4-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE DATABASE PAYMENTAPP;
Query OK, 1 row affected (0.003 sec)

MariaDB [(none)]> GRANT select,update,insert,delete ON `PAYMENTAPP`.* TO 'paymentapp'@'10.0.1.0/255.255.255.0' IDENTIFIED BY 'password';
Query OK, 0 rows affected (0.003 sec)

MariaDB [(none)]> exit
Bye
```

#### データベースにテーブルと初期データを作成する

データベース`PAYMENTAPP`に、テーブルや初期データを作成します。
ここでは手動で実施しますが、PRODUCTIONでは Flyway 等のDBマイグレーションツールを使うことをお勧めします。  
[lerna-sample-payment-app/docker/mariadb/initdb/]
にあるすべての SQL文をデータベース`PAYMENTAPP`に対して実行してください。

例えば、[lerna-sample-payment-app/docker/mariadb/initdb/] にあるすべての SQL 文を、
あらかじめ 1つの SQL ファイル `init.sql` にまとめておきます。
```shell
# lerna-sample-payment-app を clone し、
# docker/mariadb/initdb にて次のコマンドを実行します。
cat *.sql > ./init.sql
```

`init.sql` を コマンド `scp` を使い、MariaDB サーバに転送します。
```shell
# {user} と {host} は 適切なものに置き換えてください
scp ./init.sql {user}@{host}:~/
```

SQLファイルをデータベース `PAYMENTAPP` に対して実行するには、
MariaDB サーバにて次のコマンドを実行します。

```shell
$ mysql -u root -p'password' PAYMENTAPP < ./init.sql
```


### Cassandra をセットアップする
※`terraform apply` 後に実施してください。  
Cassandra サービスを起動している必要があります。  
Cassandra サービスを起動するには [各サービスの起動と再起動](/docs/ops/各サービスの起動と再起動.md) をご確認ください。

Cassandra クラスタで、keyspace と table を作成します。  
※ Cassandra クラスタが複数台で構成されている場合でも、1台のサーバに対してのみ下記作業を実施します。
作業対象の Cassandra サーバは任意のものを選んで問題ありません。


keyspace と table を作成するために、  
[resources/lerna-sample-payment-app.cql](resources/lerna-sample-payment-app.cql) を実行してください。  
この CQL ファイルは Cassandra クラスタを 3台以上で構成することを想定しているため Replication Factor が 3 と設定されています。  
Cassandra クラスタを3台未満で構成する場合には、Replication Factor をサーバ台数以下となるように調整してください。

Cassandra サーバに、コマンド `scp` でファイルをコピーします。
```shell
# {user} と {host} は 適切なものに置き換えてください
scp resources/lerna-sample-payment-app.cql {user}@{host}:~/
```

CQLを実行するには、Cassandraサーバにて次のコマンドを実行します。

```shell
$ cqlsh -u cassandra -p cassandra -e "SOURCE './lerna-sample-payment-app.cql'"
```

keyspace や table の作成に成功したことを確認します。

keyspace が作成できたことを確認するため、次のコマンドを実行してください。
2つのキースペース (`akka_example`, `akka_tenant_a`) が表示されていることを確認してください。

```shell
$ cqlsh -u cassandra -p cassandra -e "DESCRIBE KEYSPACES"

payment_app_sequence_example  system_schema  system_distributed
akka_tenant_a                 system_auth    system_traces
akka_example                  system         payment_app_sequence_tenant_a

```

table の作成に成功したことを確認するため、次のコマンドを実行してください。
`akka_example` と `akka_tenant_a` それぞれに、次の6つの table が表示されることを確認してください。

- messages
- tag_views
- tag_write_progress
- tag_scanning
- metadata
- all_persistence_ids

```shell
$ cqlsh -u cassandra -p cassandra -e "DESCRIBE TABLES"

Keyspace payment_app_sequence_example
-------------------------------------
sequence_reservation

Keyspace akka_tenant_a
----------------------
tag_views  tag_scanning         tag_write_progress
messages   all_persistence_ids  metadata

Keyspace akka_example
---------------------
tag_views  tag_scanning         tag_write_progress
messages   all_persistence_ids  metadata

Keyspace system_schema
----------------------
tables     triggers    views    keyspaces  dropped_columns
functions  aggregates  indexes  types      columns

Keyspace system_auth
--------------------
resource_role_permissons_index  role_permissions  role_members  roles

Keyspace system
---------------
available_ranges          peers               batchlog        transferred_ranges
batches                   compaction_history  size_estimates  hints
prepared_statements       sstable_activity    built_views
"IndexInfo"               peer_events         range_xfers
views_builds_in_progress  paxos               local

Keyspace system_distributed
---------------------------
repair_history  view_build_status  parent_repair_history

Keyspace system_traces
----------------------
events  sessions

Keyspace payment_app_sequence_tenant_a
--------------------------------------
sequence_reservation

```


## アプリ(`lerna-sample-payment-app`) を起動する

アプリサーバで、[lerna-sample-payment-app] を起動するために次のコマンドを実行します。
```shell
$ sudo systemctl start lerna-sample-payment-app
```

アプリサーバが起動しているかを確認するため、次のコマンドを実行し、`Active: active(running)` となっていることを確認してください。
```shell
$ systemctl status lerna-sample-payment-app
● lerna-sample-payment-app.service - lerna-sample-payment-app
   Loaded: loaded (/usr/lib/systemd/system/lerna-sample-payment-app.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/lerna-sample-payment-app.service.d
           └─override.conf
   Active: active (running) since Wed 2021-03-10 08:08:58 UTC; 5min ago
```


## 動作確認


アプリサーバが起動できた後、次のように lerna-sample-payment-app に Gatling サーバーからHTTPリクエストを送ることができます。  
※ <Keepalived の仮想IP> = 192.168.100.100 としています。必要に応じて適宜変更してください。
```shell
$ curl --include --max-time 3 --noproxy '*' --show-error --insecure \
   -H 'Authorization:Bearer dummy' \
   -H 'Content-Type:application/json' \
   -H 'X-Tenant-Id:example' \
   -X PUT -d '{ "amount":600 }' \
   https://192.168.100.100/00/ec/settlements/000000000000000000000000000000000000002/$(date +%s%3N)/payment

HTTP/1.1 200 OK
server: akka-http/10.1.12
date: Wed, 10 Mar 2021 08:17:35 GMT
content-type: application/json; charset=UTF-8
content-length: 84

{"orderId":"1615364255264","walletShopId":"000000000000000000000000000000000000002"}
```

※ SSL に自己署名証明書 を使っているため、`-k/--insecure` オプションが必要です。  
※ curl がタイムアウトした場合は、Keepalived、tunl0-supervisor、HAProxy、アプリケーションがそれぞれ正常稼働しているか確認してください。


[lerna-sample-payment-app]: https://github.com/lerna-stack/lerna-sample-payment-app
[lerna-sample-payment-app/docker/mariadb/initdb/]: https://github.com/lerna-stack/lerna-sample-payment-app/tree/main/docker/mariadb/initdb
[resources]: ./resources
