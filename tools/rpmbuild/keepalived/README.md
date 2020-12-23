# Keepalived rpm のビルド

## version
`2.0.16`

バージョンを変更する場合は [rpmbuild.sh](./rpmbuild.sh) の `docker-compose run` コマンドの引数を変更してください。

## ビルド手順
1. `./rpmbuild.sh` を実行する
1. `target/` ディレクトリに `keepalived-2.0.16-1.x86_64.rpm` が作成される
