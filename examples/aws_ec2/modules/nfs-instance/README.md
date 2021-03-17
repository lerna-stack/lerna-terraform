# NFS サーバ

NFS サーバを構築します。  

※ このモジュールは開発用途を想定しています。  
*PRODUCTION* では使用しないでください。

`/etc/fstab` に `${private_ip}:${nfs_mount_path}` を指定することで NFS サーバを利用することができます。  
NFS サーバにアクセスできる すべてのコンピュータが ファイルを 読み書きすることができます。

## Inputs

| Name | Description |
| ---- | ----------- |
| `subnet_id` | インスタンスを起動するサブネットID |
| `security_group_id` | インスタンスに付与するセキュリティグループID |
| `private_ip` | インスタンスに付与する Private IP |
| `instance_type` | インスタンスタイプ |
| `keypair_key_name` | インスタンスに指定する KeyPair の Key名 |
| `ssh_private_key` | インスタンスに接続するために使用する秘密鍵 |
| `nfs_export_path` | *NFS* で公開するファイルパス |
| `ami` | インスタンスのAMI (デフォルト=`ami-089a156ea4f52a0a3`) |
| `ssh_user` | インスタンスに接続するために使用するユーザ名 (デフォルト=`centos`) |
| `tags` | インスタンスに付与するタグ (デフォルト=`{}`) |

## Outputs

| Name | Description |
| ---- | ----------- |
| `instance_id` | 作成されたインスタンスの ID |
| `private_ip` | 作成されたインスタンスに付与された Private IP |
| `nfs_export_path` | *NFS* で公開されているファイルパス |
