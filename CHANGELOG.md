# 変更履歴

lerna-terraform に関する注目すべき変更はこのファイルで文書化されます。

このファイルの書き方については [変更履歴の書き方](docs/dev/変更履歴の書き方.md) を参照してください。

## Unreleased
- Red Hat Enterprise Linux 7 (RHEL7) に対応する
  - [RedHatEnterpriseLinux7利用ガイド](docs/dev/RedHatEnterpriseLinux7利用ガイド.md)
- Cassandraバックアップ方式を刷新します
  - 新方式は `レプリケーションファクタ < ノード数` の場合をサポートします  
    詳細は [Cassandraバックアップ方式](docs/dev/Cassandraバックアップ方式.md) をご確認ください。
  - Cassandraバックアップのシェルスクリプトを刷新します  
    スクリプトに記載している Cassandra サーバの IP アドレス (`PROD_HOSTS`, `DR_HOSTS`) を再び書き換える必要があります。
  - バックアップファイルの命名規則を変更します  
    詳細は [Cassandraバックアップ](docs/ops/Cassandraバックアップ.md) をご確認ください。
  - バックアップとリストアの手順を変更します  
    詳細は [Cassandraバックアップ](docs/ops/Cassandraバックアップ.md) と [Cassandraリストア](docs/ops/Cassandraリストア.md) をご確認ください。

## v1.0.0
初回リリース
