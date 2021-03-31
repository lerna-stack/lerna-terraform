# マイグレーションガイド

## v1.1.0 from v1.0.0

### モジュール名の変更

Red Hat Enterprise Linux サポートに伴い、
次の2つのモジュール名が変更となりました。

- `service/centos/core` => `service/redhat/core`
- `service/centos/dev` => `service/redhat/dev`

マイグレーション作業では、これらのモジュールを参照している箇所を変更する必要があります。

#### 参照モジュールのURLを変更する

`*.tf` ファイルにある、該当モジュールを` source` として指定しているモジュールの `source` 指定を書き換えてください。

```terraform
// service/centos/core => service/redhat/core
module "your-module-name" {
    // v1.0.0
    // source = "github.com/lerna-stack/lerna-terraform//modules/service/centos/core?ref=v1.0.0"

    // v1.1.0
    source = "github.com/lerna-stack/lerna-terraform//modules/service/redhat/core?ref=v1.1.0"

    // ... truncated ...
}

// service/centos/dev => service/redhat/dev
module "your-module-name" {
    // v1.0.0
    // source = "github.com/lerna-stack/lerna-terraform//modules/service/centos/dev?ref=v1.0.0"

    // v1.1.0
    source = "github.com/lerna-stack/lerna-terraform//modules/service/redhat/dev?ref=v1.1.0"

    // ... truncated ...
}
```

### `terraform plan` & `apply` を実行する

`*.tf` ファイルの書き換えが終わった後、
terraform が新しいモジュールを使えるように `terraform init` を実行し、エラーが出ないことを確認してください。


`terraform init` でエラーがでないことを確認できたら、
実際の環境とterraform との差分を確認するため `terraform plan` を実行します。
差分には、次の2種類のみが含まれることを確認してください。  
- `module.{your_module_name}.null_resource.mariadb`
- `module.{your_module_name}.null_resource.mariadb_config`

注意事項
- ユーザごとにリソースIDは異なります。
- `{your_module_name}` には、 `*.tf` ファイルにて `service/centos/core` を `source` に指定しているモジュール名が入ります。
  `{your_module_name}` に入るモジュール名はユーザごとに異なります。
- MaraDBのインスタンス数によって表示される件数が異なります。  
  MariaDBのインスタンス数 x2 の差分が表示されます。


```shell
[***]$ terraform plan

(... truncated ...)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # module.lerna_stack_service_core.null_resource.mariadb[0] must be replaced
-/+ resource "null_resource" "mariadb" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = { # forces replacement
          ~ "mariadb_repo" = "********************************" -> "********************************"
        }
    }

  # module.lerna_stack_service_core.null_resource.mariadb[1] must be replaced
-/+ resource "null_resource" "mariadb" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = { # forces replacement
          ~ "mariadb_repo" = "********************************" -> "********************************"
        }
    }

  # module.lerna_stack_service_core.null_resource.mariadb_config[0] must be replaced
-/+ resource "null_resource" "mariadb_config" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = {
          - "galera_cnf" = "********************************"
          - "mariadb"    = "*******************"
        } -> (known after apply) # forces replacement
    }

  # module.lerna_stack_service_core.null_resource.mariadb_config[1] must be replaced
-/+ resource "null_resource" "mariadb_config" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = {
          - "galera_cnf" = "********************************"
          - "mariadb"    = "*******************"
        } -> (known after apply) # forces replacement
    }

Plan: 4 to add, 0 to change, 4 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

```

差分に問題がないことが確認できたら、
差分を環境に反映するため `terraform apply` を実行します。

```shell
[***]$ terraform apply

(... truncated ...)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # module.lerna_stack_service_core.null_resource.mariadb[0] must be replaced
-/+ resource "null_resource" "mariadb" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = { # forces replacement
          ~ "mariadb_repo" = "********************************" -> "********************************"
        }
    }

  # module.lerna_stack_service_core.null_resource.mariadb[1] must be replaced
-/+ resource "null_resource" "mariadb" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = { # forces replacement
          ~ "mariadb_repo" = "********************************" -> "********************************"
        }
    }

  # module.lerna_stack_service_core.null_resource.mariadb_config[0] must be replaced
-/+ resource "null_resource" "mariadb_config" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = {
          - "galera_cnf" = "********************************"
          - "mariadb"    = "*******************"
        } -> (known after apply) # forces replacement
    }

  # module.lerna_stack_service_core.null_resource.mariadb_config[1] must be replaced
-/+ resource "null_resource" "mariadb_config" {
      ~ id       = "*******************" -> (known after apply)
      ~ triggers = {
          - "galera_cnf" = "********************************"
          - "mariadb"    = "*******************"
        } -> (known after apply) # forces replacement
    }

Plan: 4 to add, 0 to change, 4 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
  
(... truncated ...)

Apply complete! Resources: 4 added, 0 changed, 4 destroyed.
```

`terraform apply` に成功したらマイグレーション完了です。
