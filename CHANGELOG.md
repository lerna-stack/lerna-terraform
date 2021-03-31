# 変更履歴

lerna-terraform に関する注目すべき変更はこのファイルで文書化されます。

このファイルの書き方については [変更履歴の書き方](docs/dev/変更履歴の書き方.md) を参照してください。

## Unreleased

## v1.1.0
- モジュール名を変更します  
  `service/centos/core` を `service/redhat/core` に変更します。
  `service/centos/dev` を `service/redhat/dev` に変更します。  
  v1.0.0を利用している場合は移行作業が必要になります。  
  詳細は [マイグレーションガイド v1.1.0 from v1.0.0](MIGRATION.md#v110-from-v100) をご確認ください。
- Red Hat Enterprise Linux 7 (RHEL7) に対応します  
  利用方法は [RedHatEnterpriseLinux7利用ガイド](docs/dev/RedHatEnterpriseLinux7利用ガイド.md) をご確認ください。
- アプリ停止のタイムアウト値を設定可能にします  
  `app_stop_timeout_sec` で設定できます。  
  アプリケーションのグレースフルシャットダウンよりも十分な時間にするため、  
  デフォルト値を 5秒 から 5分 に変更します。
- Cassandraバックアップ方式を刷新します
    - 新方式は `レプリケーションファクタ < ノード数` の場合をサポートします  
      詳細は [Cassandraバックアップ方式](docs/dev/Cassandraバックアップ方式.md) をご確認ください。
    - Cassandraバックアップのシェルスクリプトを刷新します  
      スクリプトに記載している Cassandra サーバの IP アドレス (`PROD_HOSTS`, `DR_HOSTS`) を再び書き換える必要があります。
    - バックアップファイルの命名規則を変更します  
      詳細は [Cassandraバックアップ](docs/ops/Cassandraバックアップ.md) をご確認ください。
    - バックアップとリストアの手順を変更します  
      詳細は [Cassandraバックアップ](docs/ops/Cassandraバックアップ.md) と [Cassandraリストア](docs/ops/Cassandraリストア.md) をご確認ください。
- ネットワーク分断時、HAProxyが切り離されない問題を修正します  
  ネットワーク分断時にはマイノリティ側ではアプリが全滅する。その際、HAProxyは転送先がないが Keepalived からのヘルスチェックに OK を返すため Keepalived に切り離されず、エラーの原因となっていた。

## v1.0.0
初回リリース
