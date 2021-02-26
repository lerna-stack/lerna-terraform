#!/bin/bash

readonly virtual_ips_file='/etc/tunl0-supervisor/virtual-ips'

modprobe ipip         # ここで tunl0 が作成される
ip link set tunl0 up
# tunl0 デバイスに直接仮想 IP をつける
# 参照: http://www.austintek.com/LVS/LVS-HOWTO/HOWTO/LVS-HOWTO.LVS-Tun.html#need_tun_device

if ! [[ -r "${virtual_ips_file}" ]]
then
  echo "Could not read file: ${virtual_ips_file}" >&2
  exit 1
fi

virtual_ips="$(cat "${virtual_ips_file}" | sed -E -e '/^ *$/d')"

for virtual_ip in ${virtual_ips}
do
  ip addr add dev tunl0 ${virtual_ip}/32 brd ${virtual_ip}
done

function tunl0_is_healthy {
       test $(ip link show up dev tunl0 | wc -l) -gt 0 \
    && echo "${virtual_ips}" | xargs -I %VIP% bash -c 'test $(ip addr show dev tunl0 up to %VIP% | wc -l) -gt 0'
}

while tunl0_is_healthy
do
    sleep 1
done

# ヘルスチェックに失敗するとループを抜けてエラーになる
exit 1
