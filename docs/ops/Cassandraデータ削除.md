# cassandra クリア
- cassandraはレプリケーションされているので1台野データ削除を行えば他のサーバにも反映される。

```bash {cmd: ["ssh", "{{servers.cassandra[0]}}"]}
cqlsh -e "TRUNCATE akka.tag_write_progress;"
cqlsh -e "TRUNCATE akka.tag_views;"
cqlsh -e "TRUNCATE akka.messages;"
cqlsh -e "TRUNCATE akka.tag_scanning;"
cqlsh -e "TRUNCATE akka.metadata;"
```
