# Terraform プロジェクト初期構成ガイド

本プロジェクトのモジュールを自プロジェクトで利用する方法を示します。

## Terraform プロジェクトの作成

[env_template](/env_template) を自プロジェクトのリポジトリへコピーし、ディレクトリを任意の名前にリネームします（例: `env_aws`）。

このディレクトリには本リポジトリで提供されている全モジュールのテンプレートが格納されています。不要なモジュールがあれば削除してください。

コピーしたディレクトリ直下の `facility-*.tf` を開き、必須項目とデフォルト値が設定されている部分をプロジェクトの要件に合わせて編集し、リポジトリにコミットし、他のメンバーに共有します。

リポジトリにコミットしたくないクレデンシャル情報などは `variables.tf` に変数を定義し、`module` から参照します。

`terraform.tfvars` は git の管理外なので、個人の設定がリポジトリで共有されてしまうのを防ぐことができます。

[examples/aws_ec2](/examples/aws_ec2) プロジェクトは [platform/aws/ec2](/modules/platform/aws/ec2) モジュールと [service/redhat/core](/modules/service/redhat/core) モジュールを組み合わせた例です。
Terraform プロジェクトを新しく構成する際の参考として参照してください。
