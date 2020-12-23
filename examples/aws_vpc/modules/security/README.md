# Security Module

`lerna-stack` を構築するために必要な 認証/認可情報 を作成します。

## keepalived_instance_iam_role_id

`Keepalived` のEC2インスタンスが ルートテーブル書き換えるために必要な権限のある IAM role IDです。  
リソース制限付きで、次の3つの権限が付与されます。

- `ec2:CreateRoute`
- `ec2:DeleteRoute`
- `ec2:ReplaceRoute`
