#!/bin/bash
###################################################
#  Script name  : APP_cassandra_backup_kick.sh
#  Description  : cassandraのバックアップとNFSマウントshellをキックする
#  Server type  : Cassandra
#  User         : reactivejob
#  Usage        :
#  Returns      : 0:success 1:failure
###################################################
###############################
#define
###############################
set -o pipefail

readonly LOGNAME=/apl/var/log/cassandra/cassandra_backup.log
readonly BACKUP_KEYSPACES_CONF_PATH='/opt/management/config/backup_keyspaces.conf'
readonly SSH_USER='reactivejob'
readonly PROD_HOSTS=("")  # FIXME: 設定
readonly DR_HOSTS=("")  # FIXME: 設定
readonly REPLICATION_FACTOR=3

RC=0

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

    if [[ ${TENANT_ID} == "" ]]; then
        local TENANT_ID="unknown"
    fi

    /bin/echo -e "$(date +%Y/%m/%d\ %H:%M:%S)\t${base_dir}\t$(whoami)\texit_code:${RC}\t${LEVEL}\t${MSG}\ttenant_id:${TENANT_ID}" | tee --append ${LOGNAME}
}

###############################
#check execute user
###############################
function validate_user {
  local USER
  USER=$(whoami)
  if [[ ${USER} != "${SSH_USER}" ]] ; then
      RC=1
      log ${RC} "please execute job with user : ${SSH_USER} !![${USER}]"
      exit 1
  fi
}

###############################
#check if tenant_id is invalid
###############################
function is_valid_tenant() {
    local TEMP_TENANT_ID=$1
    for VALID_TENANT_ID in ${TENANT_ID_LIST};
    do
      if [[ ${VALID_TENANT_ID} == "${TEMP_TENANT_ID}" ]] ; then
        return 0
      fi
    done
    return 1
}

###############################
#check back keyspace config file
###############################
function check_keysapce_config() {
  local KEYSPACE_CONF="$1"
  local ALL_KEYSPACE_LIST=()
  read -r -a ALL_KEYSPACE_LIST <<< "$(/bin/echo "${KEYSPACE_CONF}"  | sed -E '/^\s*(#|$)/d' | awk '{ print $2 }')"
  local ALL_KEYSPACE_LIST_UNIQUE=()
  read -r -a ALL_KEYSPACE_LIST_UNIQUE <<< "$(/bin/echo "${KEYSPACE_CONF}"  | sed -E '/^\s*(#|$)/d' | awk '{ print $2 }' | sort -u)"
  if [[ ${#ALL_KEYSPACE_LIST_UNIQUE[@]} -ne ${#ALL_KEYSPACE_LIST[@]} ]] ; then
      RC=1
      log ${RC} "Duplicated keyspace, every keyspace should be only once in config '/opt/management/config/backup_keyspaces.conf'."
      exit 1
  else
      log ${RC} "Backup keyspace config check ok!"
      exit 0
  fi
}

###############################
#check tenant id
###############################
function parse_arguments() {
    if [[ $# -eq 0 || -z "$1" ]] ; then
      RC=1
      log ${RC} "Missed parameter, please give a tenant_id."
      exit 1
    fi
    if [[ $# -ne 1 ]] ; then
      RC=1
      log ${RC} "Too many parameters, only one tenant_id needed."
      exit 1
    fi

    # Load keyspace config
    KEYSPACE_CONF=$(<"${BACKUP_KEYSPACES_CONF_PATH}") ; RC=${?}
    if [[ ${RC} -ne 0 ]] ; then
        log ${RC} "Keyspace config file : /opt/management/config/backup_keyspaces.conf not exsist, please check."
        exit 1
    fi

    # Handle operation argument
    for i in "$@"
    do
    case $i in
        -c|--check)
        check_keysapce_config "${KEYSPACE_CONF}"
        shift # past argument=value
        ;;
        -*)
        # unknown option
        RC=1
        log ${RC} "unknown option, please input -c|--check"
        exit 1
        ;;
    esac
    done

    readonly TENANT_ID="$1"
    # Get valid tenant_id list from config file
    readonly TENANT_ID_LIST=$(/bin/echo "${KEYSPACE_CONF}" | sed -E '/^\s*(#|$)/d' | awk '{ print $1 }' | sort -u)
    # Get keyspaces from config file
    readonly KEYSPACE_LIST=$(/bin/echo "${KEYSPACE_CONF}"  | sed -E '/^\s*(#|$)/d' | awk -v tenant_id="${TENANT_ID}" 'tenant_id == $1 { print $2 }' | sort -u)
    # Check whether the input tenant_id is valid
    is_valid_tenant "${TENANT_ID}" ; RC=${?}
    if [[ ${RC} -ne 0 ]] ; then
        # transpose list to line with delimiter comma
        local TENANT_ID_LIST_LOG
        TENANT_ID_LIST_LOG=$(/bin/paste --serial --delimiters=',' <<< "${TENANT_ID_LIST}")
        log ${RC} "Invalid tenant_id : ${TENANT_ID}, only supported one of (${TENANT_ID_LIST_LOG})."
        exit 1
    fi
}

###############################
#main
###############################
function main {
  validate_user
  RC=0
  parse_arguments "$@"
  repair
  backup
  exit_script
}

###############################
#backup
###############################
function backup {
  # calculate subarray of PROD enviroment hosts
  local PROD_NODE_NUM=${#PROD_HOSTS[@]}
  local PROD_BACKUP_NODE_NUM=$(( (1 - REPLICATION_FACTOR/PROD_NODE_NUM) * PROD_NODE_NUM + 1 ))
  readonly PROD_BACKUP_NODES=("${PROD_HOSTS[@]:0:${PROD_BACKUP_NODE_NUM}}")
  # take prod env backup
  for PROD_HOST in "${PROD_BACKUP_NODES[@]}";
  do
      RC=0
      log ${RC} "Backup ${PROD_HOST} is started."
      execute_remote_backup "${PROD_HOST}"
  done
}


###############################
#execute_remote_backup
#remote call backup script
###############################
function execute_remote_backup {
    local EXE_IP_HOST=$1
    ssh "${SSH_USER}@${EXE_IP_HOST}"  "/opt/management/bin/APP_cassandra_backup_execute.sh  '${TENANT_ID}' '${KEYSPACE_LIST}' '${EXE_IP_HOST}'"
    RC=${?}
    if [[ ${RC} -ne 0 ]] ; then
        log ${RC} "Backup ${EXE_IP_HOST} is abnormal end."
    else
        log ${RC} "Backup ${EXE_IP_HOST} is success."
    fi
}

###############################
#repair
#repairは失敗してもエラーログのみ出力し後続の処理は継続する
###############################
function execute_remote_repair() {
    local IP_HOST=$1
    local KEYSPACE=$2
    ssh "${SSH_USER}@${IP_HOST}" nodetool repair -pr "${KEYSPACE}" ; RC=${?}
    if [[ ${RC} -ne 0 ]] ; then
        log ${RC} "Repair ${IP_HOST} is abnormal end."
    else
        log ${RC} "Repair ${IP_HOST} is success."
    fi
}

###############################
#repair
#repairは失敗してもエラーログのみ出力し後続の処理は継続する
###############################
function repair {
  # prod repair
  for PROD_HOST in "${PROD_HOSTS[@]}";
  do
      for KEYSPACE in ${KEYSPACE_LIST}
      do
          execute_remote_repair "${PROD_HOST}" "${KEYSPACE}"
      done
  done

  # dr repair
  for DR_HOST in "${DR_HOSTS[@]}";
  do
      for KEYSPACE in ${KEYSPACE_LIST}
      do
          execute_remote_repair "${DR_HOST}" "${KEYSPACE}"
      done
  done
}

###############################
#exit
###############################
function exit_script {
  if [[ ${RC} -eq 0 ]] ; then
      log ${RC} "backup cassandra is normal end."
  fi

  exit ${RC}
}

main "$@"
