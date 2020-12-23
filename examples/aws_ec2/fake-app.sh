#!/bin/bash

# リクエスト受付用エンドポイント
socat -v -v tcp4-listen:9001,reuseaddr,fork,crlf system:'
  echo "HTTP/1.0 200 OK"
  echo "Content-Type: text/plain"
  echo "Date: $(date)"
  echo "Server: ${SOCAT_SOCKADDR}:${SOCAT_SOCKPORT}"
  echo "Client: ${SOCAT_PEERADDR}:${SOCAT_PEER_PORT}"
  echo "Connection: close"
  echo
  echo "HELLO"
' &

# ヘルスチェックエンドポイント
socat -v -v tcp4-listen:9002,reuseaddr,fork,crlf system:'
  echo "HTTP/1.0 200 OK"
  echo "Content-Type: text/plain"
  echo "Date: $(date)"
  echo "Server: ${SOCAT_SOCKADDR}:${SOCAT_SOCKPORT}"
  echo "Client: ${SOCAT_PEERADDR}:${SOCAT_PEER_PORT}"
  echo "Connection: close"
  echo
  echo "OK"
' &

wait
