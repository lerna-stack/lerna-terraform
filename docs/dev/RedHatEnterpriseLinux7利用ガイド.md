# Red Hat Enterprise Linux 利用ガイド

`modules/platform/aws/ec2` で使用するAMIとして、 *Red Hat Enterprise Linux 7 (RHEL7)* が選択できます。

## 動作確認済みAMI

[AWS Marketplace: Red Hat Enterprise Linux (RHEL) 7.2 (HVM)](https://aws.amazon.com/marketplace/pp/B019NS7T5I?qid=1612505340203&sr=0-2&ref_=srh_res_product_title)
の`ap-northeast-1`で利用可能なAMI `ami-0dd8f963` にて動作確認済みです。

## 設定方法

RHEL 7.2 (HVM) を利用するには、
`modules/platform/aws/ec2` の `aws_ami` を `ami-0dd8f963` に設定します。
AMI `ami-0dd8f963` を使う場合には追加の料金を払う必要があるため注意してください。

RHEL7 を利用するためには、幾つか追加で設定を行う必要があります。
必要な設定は次の3つです。
- ユーザ名  
  設定したAMIで利用可能なユーザ名`ec2-user`を設定する必要があります。
- EC2インスタンスタイプ  
  設定したAMIで利用可能なインスタンスタイプを設定する必要があります。
- MariaDBインストールに使用するyumリポジトリ  
  RHEL7で利用可能な yum リポジトリが使用されるように設定する必要があります。

### ユーザ名の設定

利用するユーザ名は、次に示す設定項目から変更できます。  
RHEL7 7.2 (HVM) (`ami-0dd8f963`) を使用する場合は、次のように設定できます。

- モジュール `modules/service/centos/core`  
  - 設定項目 `ssh_users`  
    インスタンスごとのsshユーザ名に `ec2-user` を設定します。  
- モジュール `modules/service/centos/dev`
  - 設定項目 `ssh_users`  
    インスタンスごとのsshユーザ名に `ec2-user` を設定します。
- モジュール `modules/platform/aws/ec2`  
  - 設定項目 `ssh_user = "ec2-user"`  
    

### インスタンスタイプの設定

各種サービスのインスタンスが使用するインスタンスタイプは、次に示す設定項目から変更できます。
RHEL7 7.2 (HVM) (`ami-0dd8f963`) を使用する場合には次のように設定できます。

- モジュール `modules/platform/aws/ec2`  
  - 設定項目 `keepalived_instance_type = "c4.large"`  
  - 設定項目 `haproxy_instance_type = "c4.large"`  
  - 設定項目 `app_instance_type = "r3.large"`  
  - 設定項目 `cassandra_instance_type = "r3.xlarge"`  
  - 設定項目 `mariadb_instance_type = "r3.large"`  
  - 設定項目 `gatling_instance_type = "r3.large"`  

### MariaDBのインストールに使用するyumリポジトリの設定

MariaDBのインストール時に使用するyumリポジトリは、次に示す設定項目から変更できます。

- モジュール `modules/service/centos/core`
    - 設定項目 `mariadb_yum_repository_distribution_name = "rhel7"`  
      RHEL7 を使用するためには、`rhel7` を指定します。
