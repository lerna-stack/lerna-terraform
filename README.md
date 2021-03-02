# lerna-terraform

Lerna Stack を用いたシステムの稼働環境を構築するための Terraform モジュール

## Modules

本リポジトリが提供するモジュールは **Service layer modules** と **Platform layer modules** に大別されます。

Service layer modules は既存のサーバーに Lerna Stack を構成するのに必要なソフトウェアを構築します。
Platform layer modules は Service layer modules を適用するターゲットとなるサーバー群を作成します。

Service layer modules を単独で利用することで、プライベートクラウド上に Lerna Stack を構築することもできます。

### Service layer modules

- **[service/redhat/core]**
    - 既存のサーバー上に Lerna Stack の各種サービス（Keepalived, Cassandra など）とアプリケーションをデプロイします
    - CentOS 8, Red Hat Enterprise Linux 7 をサポートしています
    - デフォルト設定は CentOS 8 向けです  
      Red Hat Enterprise Linux 7 向けに設定する場合には、[RedHatEnterpriseLinux利用ガイド] をご覧ください
- **[service/redhat/dev]**
    - 既存のサーバー上に Lerna Stack を用いたシステムの開発環境に必要なリソースをデプロイします
    - CentOS 8, Red Hat Enterprise Linux 7 をサポートしています
    - デフォルト設定は CentOS 8 向けです  
      Red Hat Enterprise Linux 7 向けに設定する場合には、[RedHatEnterpriseLinux利用ガイド] をご覧ください

### Platform layer modules

- **[platform/aws/ec2]**
    - 既存の Amazon VPC 内に Lerna Stack を構成するための EC2 インスタンスを構築します
    - CentOS 8, Red Hat Enterprise Linux 7 をサポートしています
    - デフォルトで使用する OS は CentOS 8 です  
      使用する OS を Red Hat Enterprise Linux 7 に変更する場合には、[RedHatEnterpriseLinux利用ガイド] をご覧ください

## Examples

実際にプロジェクトで利用する際の参考となるサンプルプロジェクトを提供しています。

- **[aws_vpc](examples/aws_vpc)**
    - [platform/aws/ec2] を構築するのに必要な VPC（Virtual Private Cloud）を構築するサンプルです
- **[aws_ec2](examples/aws_ec2)**
    - [platform/aws/ec2] モジュールと [service/redhat/core] モジュールを組み合わせたサンプルです

## User Guides

  - [Terraform プロジェクト初期構成ガイド](docs/dev/Terraformプロジェクト初期構成ガイド.md)
    - Terraform プロジェクトを作成します
  - [Lerna Stack 構築ガイド](docs/dev/LernaStack構築ガイド.md)
    - 既存のサーバー上にLerna Stack の各種サービス（Keepalived, Cassandra など）とアプリケーションをデプロイします
  - [RedHatEnterpriseLinux利用ガイド]
    - [platform/aws/ec2] で使用するOSとして Red Hat Enterprise Linux 7 を選択した場合にご覧ください
    - [service/redhat/core] や [service/redhat/dev] を Red Hat Enterprise Linux 7 上に構築する場合にご覧ください
  - [マイグレーションガイド](MIGRATION.md)  
    メジャーバージョンには破壊的変更が含まれることがあります。  
    メジャーバージョンを更新する際には、必ずマイグレーションガイドを確認してください。

## Contributing

本プロジェクトの開発に参加する際は次の手順で開発環境を構築してください。

[開発環境セットアップガイド](./docs/dev/開発環境セットアップガイド.md)

バージョンアップ時には、[CHANGELOG.md](CHANGELOG.md), [MIGRATION.md](MIGRATION.md) を更新してください。

## License

lerna-terraform is released under the terms of the [Apache License Version 2.0](LICENSE).

© 2020 TIS Inc.


[service/redhat/core]: modules/service/redhat/core
[service/redhat/dev]: modules/service/redhat/dev
[platform/aws/ec2]: modules/platform/aws/ec2
[RedHatEnterpriseLinux利用ガイド]: docs/dev/RedHatEnterpriseLinux7利用ガイド.md
