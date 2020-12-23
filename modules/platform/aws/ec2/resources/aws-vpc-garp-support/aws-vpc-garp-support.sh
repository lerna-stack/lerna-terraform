#!/bin/bash
#
# Replace virtual ip route in Amazon VPC route-table by Gratuitous ARP
#
# requirements:
#   - awscli
#   - tcpdump

readonly REGION=$(curl --silent --max-time 3 --noproxy '*' 169.254.169.254/latest/meta-data/placement/availability-zone | sed -r 's/[a-z]$//')
if [[ -z "${REGION}" ]]
then
  echo 'Fetching region ID failed' >&2
  exit 1
fi

readonly INSTANCE_ID=$(curl --silent --max-time 3 --noproxy '*' 169.254.169.254/latest/meta-data/instance-id)
if [[ -z "${INSTANCE_ID}" ]]
then
  echo 'Fetching instance ID failed' >&2
  exit 1
fi

readonly NETWORK_INTERFACE="${NETWORK_INTERFACE:-none}"
readonly ROUTE_TABLE_ID="${ROUTE_TABLE_ID:-none}"
readonly virtual_ips="$(echo ${VIRTUAL_IPS} | tr ' ' '\n')"
readonly AWSCLI_TIMEOUTS='--cli-connect-timeout 1 --cli-read-timeout 1'

function init {
  if ! create
  then
    echo "Creation Failed. Skip creation..." >&2
  fi
}

function create {
  for virtual_ip in ${virtual_ips}
  do
    echo "Creating ${virtual_ip}/32 route to ${INSTANCE_ID}"

    aws --region ${REGION} ${AWSCLI_TIMEOUTS} ec2 create-route \
        --destination-cidr-block ${virtual_ip}/32 \
        --route-table-id ${ROUTE_TABLE_ID} \
        --instance-id ${INSTANCE_ID}
  done
}

function clean {
  for virtual_ip in ${virtual_ips}
  do
    echo "Deleting ${virtual_ip}/32 route to ${INSTANCE_ID}"

    aws --region ${REGION} ${AWSCLI_TIMEOUTS} ec2 delete-route \
        --destination-cidr-block ${virtual_ip}/32 \
        --route-table-id ${ROUTE_TABLE_ID}
  done
}

function is_virtual_ip {
  echo "${virtual_ips}" | grep --line-regexp --fixed-strings "$1" > /dev/null 2>&1
}

function receive_arp {
  while read who_has tell
  do
    if is_virtual_ip "${who_has}" # Gratuitous ARP
    then
      echo "Replacing ${who_has}/32 route to ${INSTANCE_ID}"

      aws --region ${REGION} ${AWSCLI_TIMEOUTS} ec2 replace-route \
        --destination-cidr-block ${who_has}/32 \
        --route-table-id ${ROUTE_TABLE_ID} \
        --instance-id ${INSTANCE_ID}
    fi
  done
}

function listen_arp {
  tcpdump -n -i "${NETWORK_INTERFACE}" -l arp \
    | grep --line-buffered 'ARP, Request' \
    | sed --unbuffered -r 's/.+ who-has ([^ ]+).+tell ([^,]+),.+/\1 \2/' \
    | receive_arp
}

case "${1:-listen_arp}" in
  "init"        ) init ;;
  "clean"       ) clean ;;
  "listen_arp"  ) init; listen_arp ;;
  * ) echo "unknown command: $1" >&2 ;;
esac
