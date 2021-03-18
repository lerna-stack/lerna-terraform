#!/bin/bash
###################################################
#  Script name  : APP_cassandra_backup.sh
#  Description  : cassandraのバックアップを起動する
#  Parameter    : テナントIDリスト
#  Server type  : Cassandra
#  User         : reactivejob
#  Usage        :
#  Returns      : 0:success 1:failure
###################################################
###############################
#define
###############################
readonly LOGNAME=/apl/var/log/cassandra/cassandra_backup.log

###############################
# log function
###############################
function log {
    local RC="${1}" MSG="${2}"
    local base_dir
    base_dir=$(basename "$0")

    if [[ "${RC}" = "0" ]]; then
        local LEVEL=INFO
    else
        local LEVEL=ERROR
    fi

    /bin/echo -e "$(date +%Y/%m/%d\ %H:%M:%S)\t${base_dir}\t$(whoami)\texit_code:${RC}\t${LEVEL}\t${MSG}" | tee --append ${LOGNAME}
}
###############################
#check parameter
###############################
function check_params {
    declare -a PARAMS_A=("$@")
    local LEN=${#PARAMS_A[@]}
    # Sort array as unique
    local SORTED_UNIQUE_TENANT_IDS_A=($(echo "${PARAMS_A[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local LEN_SU=${#SORTED_UNIQUE_TENANT_IDS_A[@]}
    # Check if parameter is empty
    if [[ LEN -eq 0 ]] ; then
      RC=1
      log ${RC} "Missed parameter, please give a tenant_id list."
      exit 1
    fi
    # Check if duplicate parameter
    if [[ LEN -ne LEN_SU ]] ; then
      RC=1
      log ${RC} "Duplicated parameters, every tenant_id should be only once."
      exit 1
    fi
}

###############################
#main
###############################
function main {
    declare -a TENANT_IDS_A=("$@")
    RC=0
    check_params ${TENANT_IDS_A[@]}
    # 各テナントが逐次実行される
    for TENANT_ID in ${TENANT_IDS_A[@]}
    do
        log ${RC} "Cassandra backup tenant id : ${TENANT_ID} is start."
        /opt/management/bin/APP_cassandra_backup_kick.sh ${TENANT_ID}
        RC=${?}
        if [[ ${RC} -ne 0 ]] ; then
            log ${RC} "Cassandra backup tenant id : ${TENANT_ID} is abnormal end."
            # if one tenant_id was failed, the others will continue
            RC=0
            continue
        else
            log ${RC} "Cassandra backup tenant id : ${TENANT_ID} is success."
        fi
    done
}

main "$@"
