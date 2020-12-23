# Lerna Stack 構築ガイド

Lerna Stack の稼働環境を構築する方法を示します。

## 準備

### 1.デプロイ対象のアプリ/ミドルウェアの RPM を用意する

#### アプリ
デプロイするRPMファイルをビルドしてください。

##### アプリケーションの要件
- HTTPの bind port は 以下の設定と対応していること
    - `app_service_port` 変数 (デフォルト `9000`)
- ヘルスチェック用 endpoint があること
    - port は `app_health_check_port` 変数 (デフォルト `9002`)
    - path は `app_health_check_path` 変数 (デフォルト `/health`)
    - レスポンス HTTP ステータスコード `200` でHealthy, 他は Unhealthy

#### ミドルウェア (Cassandra)
https://archive.apache.org/dist/cassandra/redhat/311x/ から `cassandra-3.11.4-1.noarch.rpm` をダウンロードしてください。

#### ミドルウェア (HAProxy)

OS のリポジトリにあるバージョンは古い場合があるため、独自にビルドを行います。

次の手順に従いビルドしてください。

[tools/rpmbuild/haproxy/README.md](../../tools/rpmbuild/haproxy/README.md)

#### ミドルウェア (Keepalived)

OS のリポジトリにあるバージョンは古い場合があるため、独自にビルドを行います。

次の手順に従いビルドしてください。

[tools/rpmbuild/keepalived/README.md](../../tools/rpmbuild/keepalived/README.md)

### 2. 環境設定

プロジェクトのルートディレクトリ直下の  `terraform.tfvars.example` を同じディレクトリにコピーし、`terraform.tfvars` を作成します。

必要に応じて設定値のコメントアウトを解除し、設定します。

## 環境構築

プロジェクトのルートディレクトリ直下で下記のコマンドを実行します。

```bash
terraform apply
```

[各サービスの起動と再起動](../ops/各サービスの起動と再起動.md) を参考に、各サービスを起動します。


### 確認

#### Keepalived, HAProxy, アプリケーション

`Keepalived の仮想IP` にアクセスできる環境から以下のコマンドを実行します

```
curl --include --max-time 3 --noproxy '*' --insecure https://<Keepalived の仮想IP>
```

※ SSL に自己署名証明書 を使っているため、`-k/--insecure` オプションが必要です。

何かしらの HTTP レスポンスが確認できれば、ネットワーク疎通は問題ありません。
（以下は [examples/aws_ec2](/examples/aws_ec2) の fake-app を使った例）

```
HTTP/1.0 200 OK
content-type: text/plain
date: Mon Jul 13 02:45:41 UTC 2020
server: 10.153.131.20:9001
client: 10.153.131.15:

HELLO
```

curl がタイムアウトした場合は、Keepalived、tunl0-supervisor、HAProxy、アプリケーションがそれぞれ正常稼働しているか確認してください。

#### Cassandra

Cassandra サーバーで以下のコマンドを実行

```
 cqlsh -u cassandra -p cassandra
```

適当なクエリを実行し、結果が返ってくることを確認

```
Connected to cassandra_cluster at 10.153.131.25:9042.
[cqlsh 5.0.1 | Cassandra 3.11.4 | CQL spec 3.4.4 | Native protocol v4]
Use HELP for help.
cassandra@cqlsh> SELECT now() FROM system.local;

 system.now()
--------------------------------------
 c1434180-c4b0-11ea-a819-c754bb888669

(1 rows)
```

クラスタの状態確認は `nodetool status` コマンドを実行して Cassandra サーバーが列挙されていることを確認します。

```
$ nodetool status
Datacenter: dc0
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address        Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.100.100.1  108.62 KiB  256          100.0%            5efa381a-8d0e-4ef4-ab42-17d3a1ec1923  az1
UN  10.100.100.2  88.88 KiB  256          100.0%            dba3def6-458c-4bb6-873b-f5f6c946c6c5  az1
UN  10.100.100.3  92.24 KiB  256          100.0%            2c9cfb8e-c516-483f-85f2-bd7d12bfae3f  az1
```

#### MariaDB

MariaDB サーバーで以下のコマンドを実行

```
mysql
```

適当なクエリを実行し、結果が返ってくることを確認

```
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 8
Server version: 10.5.4-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select 1;
+---+
| 1 |
+---+
| 1 |
+---+
1 row in set (0.000 sec)
```

クラスタの状態確認は、以下のクエリを発行して `wsrep_cluster_size` が MariaDB サーバーの台数と一致していれば問題ありません。

```
MariaDB [(none)]> SHOW GLOBAL STATUS LIKE 'wsrep_cluster%';
+----------------------------+--------------------------------------+
| Variable_name              | Value                                |
+----------------------------+--------------------------------------+
| wsrep_cluster_weight       | 3                                    |
| wsrep_cluster_capabilities |                                      |
| wsrep_cluster_conf_id      | 3                                    |
| wsrep_cluster_size         | 3                                    |
| wsrep_cluster_state_uuid   | 660f1db9-c4b0-11ea-bc3e-7f0430485200 |
| wsrep_cluster_status       | Primary                              |
+----------------------------+--------------------------------------+
6 rows in set (0.000 sec)
```
