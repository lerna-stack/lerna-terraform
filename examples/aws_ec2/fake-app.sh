#!/bin/bash

# リクエスト受付用エンドポイント
socat -v -v tcp4-listen:9001,reuseaddr,fork,crlf system:'
  echo "HTTP/1.0 200 OK"
  echo "Content-Type: text/plain"
  echo "Date: $(date)"
  echo "Server: ${SOCAT_SOCKADDR}:${SOCAT_SOCKPORT}"
  echo "Client: ${SOCAT_PEERADDR}:${SOCAT_PEERPORT}"
  echo "Connection: close"
  echo
  echo "HELLO"
' &

# ヘルスチェックエンドポイント
# HAProxy と組み合わせて動かすとステータスコードを返した時点でソケットがクローズされ、
# echo を複数使ってコンテンツを返そうとすると Broken Pipe エラーが発生した。
# 対策として、ステータスコードのみを返す。
socat -v -v tcp4-listen:9002,reuseaddr,fork,crlf system:'
  echo "HTTP/1.0 200 OK"
' &

wait
