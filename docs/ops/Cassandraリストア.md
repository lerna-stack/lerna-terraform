# Cassandra リストア

[Cassandraバックアップ] にてバックアップしたデータを用いて、Cassandra をリストアすることができます。  

## 前提条件

- [Cassandraバックアップ](Cassandraバックアップ.md) のとおりにバックアップしていること
- Cassandra を使用しているサービスをすべて停止していること

## リストア方法

### 0. Cassandra ノードに接続しているクライアントが存在しないことを確認する

※すべての Cassandra ノードで次の手順実施します。

Cassandra ノードに接続しているクライアントが存在しないことを確認します。

接続しているクライアントが存在しないことを確認するため、次のコマンドを実行してください。  
※ Cassandra が使用するポート番号 `9042` を変更した場合は適切にコマンドを調整してください。  
※ Cassandra 4.0+ であれば、[nodetool clientstats](https://cassandra.apache.org/doc/latest/tools/nodetool/clientstats.html) を使ってください。

```shell
# 一覧に何も表示されないことを確認してください。
# この結果は Cassandra に接続しているクライアントが存在する例を示しています。
# このように `ESTABLISHED` になっている接続がある場合には、クライアントから接続を切る必要があります。
$ netstat --tcp -a | grep 9042 | grep ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44638         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44772         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44768         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44752         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44742         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44758         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44744         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44640         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44740         ESTABLISHED
tcp        0      0 ip-10-0-1-61.ap-no:9042 10.0.1.51:44632         ESTABLISHED
```


### 1. すべての Cassandra ノードを停止する
※すべての Cassandra ノードで次の手順実施します。

Cassandra サービスを停止するため、次のコマンドを実行してください。
```shell
$ sudo systemctl stop cassandra
```

Cassandra サービスが停止したかどうかを、次のコマンドで確認してください。
```shell
$ sudo systemctl status cassandra
● cassandra.service - Cassandra
   Loaded: loaded (/etc/systemd/system/cassandra.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Wed 2021-03-17 05:21:35 UTC; 3min 9s ago
```

`Active: active`  ではないことが確認できます。   


### 2. すべての Cassandra ノードを起動する
※すべての Cassandra で、次の手順を実施します。

Cassandra サービスを停止するため、次のコマンドを実行してください。
```shell
$ sudo systemctl start cassandra
```

Cassandra サービスが起動したかどうかを、次のコマンドで確認してください。
```shell
$ sudo systemctl status cassandra
● cassandra.service - Cassandra
   Loaded: loaded (/etc/systemd/system/cassandra.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-03-17 05:26:03 UTC; 24s ago
```

`Active: active`  となっていることが確認できます。


### 3. Cassandra クラスタの状態を確認する

※いずれか1つの Cassandra ノードで、次の手順を実施します。

Cassandra クラスタの状態を確認するため、次のコマンドを実行してください。

```shell
$ nodetool status
Datacenter: dc0
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address    Load       Tokens       Owns    Host ID                               Rack
UN  10.0.1.61  350.5 KiB  256          ?       909e044f-d0af-426a-abff-901f890ac512  az1
UN  10.0.1.62  404.55 KiB  256          ?       b672ba56-8859-4cf9-9241-9409f86ec86d  az1
UN  10.0.1.63  448.07 KiB  256          ?       53b736eb-199b-4f8b-b358-e1eaa287161d  a
```

Cassandra ノードがすべて *UN*  でクラスタに参加していることが確認できます。


### 4. Cassandra クラスタからデータを削除する

※いずれか1つの Cassandra ノードで、次の手順を実施します。

バックアップを復元する前に、 Cassandra クラスタからデータを削除します。

Cassandra クラスタからデータを削除するため、次のコマンドを実行してください。  
※ データを削除する テーブルは適切に変更してください。  
この例では、次の6つのテーブルからデータを削除します。
- `akka_example.all_persistence_ids`
- `akka_example.messages`
- `akka_example.metadata`
- `akka_example.tag_scanning`
- `akka_example.tag_view`
- `akka_example.tag_write_progress`

```shell
$ cqlsh -u cassandra -p cassandra <<EOF
// すべてのノードに対して TRUNCATE を実行します
CONSISTENCY ALL;
// 次のテーブル名は、適切に変更してください
TRUNCATE akka_example.tag_write_progress;
TRUNCATE akka_example.tag_views;
TRUNCATE akka_example.messages;
TRUNCATE akka_example.tag_scanning;
TRUNCATE akka_example.metadata;
TRUNCATE akka_example.all_persistence_ids;
EOF
```

### 5. Cassandra ノードにデータを投入する

※ バックアップを取得されたノードにデータを投入します。

バックアップデータを、Cassandra ノードに投入します。  
ここでは1つのノードにデータを投入する手順を示します。  
**バックアップデータが複数ある場合には、それぞれのバックアップデータを対応する Cassandra ノードに投入してください。**  

Cassandra ノードにデータを投入するため、次のコマンドを実行してください。  
※ 投入するデータは適切に変更してください。  
この例では、次の6つのテーブルにデータを投入します。  
- `akka_example.all_persistence_ids`
- `akka_example.messages`
- `akka_example.metadata`
- `akka_example.tag_scanning`
- `akka_example.tag_view`
- `akka_example.tag_write_progress`

```
# Copy backup data from your backup storage
[centos@10-0-1-61]$ mount /apl/cassandra_backup
[centos@10-0-1-61]$ ls /apl/cassandra_backup
cassandra_example_10.0.1.61_20210319_032137.tar.gz  cassandra_example_10.0.1.62_20210319_032139.tar.gz
# 投入するノードと同じ IP アドレスのバックアップデータを使用してください
[centos@10-0-1-61]$ cp /apl/cassandra_backup/cassandra_example_10.0.1.61_20210319_032137.tar.gz ./
[centos@10-0-1-61]$ umount /apl/cassandra_backup

# Extract files from backup data
$ tar xfvz cassandra_example_20210317_070616.tar.gz
# (truncated...)
$   ls var/lib/cassandra/data/akka_example/
all_persistence_ids-ac59b410886011ebab97a3af832d5902  metadata-abb0c9e0886011ebab97a3af832d5902      tag_views-aa6a6730886011ebab97a3af832d5902
messages-a9b9dbe0886011ebab97a3af832d5902             tag_scanning-ab241a40886011ebab97a3af832d5902  tag_write_progress-aa987c10886011ebab97a3af832d590

# Place backup files to /var/lib/cassandra/data
$ sudo mv \
  -t /var/lib/cassandra/data/akka_example/all_persistence_ids-ac59b410886011ebab97a3af832d5902/ \
      var/lib/cassandra/data/akka_example/all_persistence_ids-ac59b410886011ebab97a3af832d5902/snapshots/cassandra_example_10.0.1.61_20210319_032137/*
$ sudo mv \
  -t /var/lib/cassandra/data/akka_example/messages-a9b9dbe0886011ebab97a3af832d5902/ \
      var/lib/cassandra/data/akka_example/messages-a9b9dbe0886011ebab97a3af832d5902/snapshots/cassandra_example_10.0.1.61_20210319_032137/*
$ sudo mv \
  -t /var/lib/cassandra/data/akka_example/metadata-abb0c9e0886011ebab97a3af832d5902/ \
      var/lib/cassandra/data/akka_example/metadata-abb0c9e0886011ebab97a3af832d5902/snapshots/cassandra_example_10.0.1.61_20210319_032137/*
$ sudo mv \
  -t /var/lib/cassandra/data/akka_example/tag_scanning-ab241a40886011ebab97a3af832d5902/ \
      var/lib/cassandra/data/akka_example/tag_scanning-ab241a40886011ebab97a3af832d5902/snapshots/cassandra_example_10.0.1.61_20210319_032137/*
$ sudo mv \
  -t /var/lib/cassandra/data/akka_example/tag_views-aa6a6730886011ebab97a3af832d5902/ \
      var/lib/cassandra/data/akka_example/tag_views-aa6a6730886011ebab97a3af832d5902/snapshots/cassandra_example_10.0.1.61_20210319_032137/*
$ sudo mv \
  -t /var/lib/cassandra/data/akka_example/tag_write_progress-aa987c10886011ebab97a3af832d5902/ \
      var/lib/cassandra/data/akka_example/tag_write_progress-aa987c10886011ebab97a3af832d5902/snapshots/cassandra_example_10.0.1.61_20210319_032137/*

# Reload SSTable
$ nodetool refresh -- akka_example all_persistence_ids
$ nodetool refresh -- akka_example messages
$ nodetool refresh -- akka_example metadata
$ nodetool refresh -- akka_example tag_scanning
$ nodetool refresh -- akka_example tag_views
$ nodetool refresh -- akka_example tag_write_progress
```

### 6. Cassandraノードで リペアを実行する

※ すべての Cassandra ノードで次の手順を実施してください。

リペアを行うために、次のコマンドを実行してください。
```shell
$ nodetool repair -pr -full
# (... truncated)
[2021-03-17 06:08:28,443] Repair completed successfully
[2021-03-17 06:08:28,443] Repair command #3 finished in 0 seconds
```

### 7. データが復元されたことを確認する

プロジェクトに応じた適切な方法で、データが復元されたことを確認してください。  
例えば `cqlsh` コマンドを用いて、データを読み込む等の方法があります。



[Cassandraバックアップ]: Cassandraバックアップ.md
