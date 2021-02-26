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
readonly NODE_BACKUP_DIR=/apl/cassandra_backup
readonly SSH_USER='reactivejob'
readonly EXECUTE_HOST="" # FIXME: 設定
readonly PROD_HOSTS=("")  # FIXME: 設定
readonly DR_HOSTS=("")  # FIXME: 設定
readonly GENERATION_DAIRY=3
readonly BASE_FILE_NAME=cassandra
readonly CASSANDRA_DATA_DIR=/var/lib/cassandra/data
readonly TENANT_ID_WITH_LEGACY_BACKUP_FILE_FORMAT=""  # FIXME: 設定

RC=0

###############################
# log function
###############################
function log {
    local RC="${1}" MSG="${2}"

    if [[ "${RC}" = "0" ]]; then
        local LEVEL=INFO
    else
        local LEVEL=ERROR
    fi

    if [[ ${TENANT_ID} == "" ]]; then
        local TENANT_ID="unknown"
    fi

    /bin/echo -e "$(date +%Y/%m/%d\ %H:%M:%S)\t$(basename $0)\t$(whoami)\texit_code:${RC}\t${LEVEL}\t${MSG}\ttenant_id:${TENANT_ID}" | tee --append ${LOGNAME}
}

###############################
#check execute user
###############################
function validate_user {
  local USER=$(whoami)
  if [[ ${USER} != "reactivejob" ]] ; then
      RC=1
      log ${RC} "please execute reactivejob user!![${USER}]"
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
      if [[ ${VALID_TENANT_ID} == ${TEMP_TENANT_ID} ]] ; then
        return 0
      fi
    done
    return 1
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

    readonly TENANT_ID="$1"
    # Get valid tenant_id list from config file
    readonly TENANT_ID_LIST=$(/bin/echo "${KEYSPACE_CONF}" | sed -E '/^\s*(#|$)/d' | awk '{ print $1 }' | sort -u)
    # Get keyspaces from config file
    readonly KEYSPACE_LIST=$(/bin/echo "${KEYSPACE_CONF}"  | sed -E '/^\s*#/d' | awk -v tenant_id="${TENANT_ID}" 'tenant_id == $1 { print $2 }')
    # Setting SNAPSHOT_NAME with tenant_id
    readonly SNAPSHOT_NAME="${BASE_FILE_NAME}_${TENANT_ID}_$(date '+%Y%m%d_%H%M%S')"
    # Check whether the input tenant_id is valid
    is_valid_tenant "${TENANT_ID}" ; RC=${?}
    if [[ ${RC} -ne 0 ]] ; then
        # transpose list to line with delimiter comma
        local TENANT_ID_LIST_LOG=$(/bin/paste --serial --delimiters=',' <<< "${TENANT_ID_LIST}")
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
  take_snapshot
  mount_backup_storage
  # 終了(正常・異常問わない)したら アンマウント して、次回実行時のマウント時エラーを回避する
  trap "unmount_backup_storage" EXIT
  send_archive_to_backup_server
  rotate_archives
  clear_snapshot
  exit_script
}

###############################
#repair
#repairは失敗してもエラーログのみ出力し後続の処理は継続する
###############################
function execute_remote_repair() {
    local IP_HOST=$1
    local KEYSPACE=$2
    ssh ${SSH_USER}@${IP_HOST} nodetool repair -pr "${KEYSPACE}" ; RC=${?}
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
          execute_remote_repair "${PROD_HOST}" "${KEYSPACE}"
      done
  done
}

###############################
#execute_take_snapshot
###############################
function execute_take_snapshot {
  local KEYSPACE=$1
  nodetool snapshot -t "${SNAPSHOT_NAME}" "${KEYSPACE}" ; RC=${?}
  if [[ ${RC} -ne 0 ]] ; then
      log ${RC} "Snapshot ${KEYSPACE} ${EXECUTE_HOST} is abnormal end."
      exit 1
  else
      log ${RC} "Snapshot ${KEYSPACE} ${EXECUTE_HOST} is success."
  fi
}
###############################
#snapshot
###############################
function take_snapshot {
  for KEYSPACE in ${KEYSPACE_LIST}
  do
      execute_take_snapshot "${KEYSPACE}"
  done
}


###############################
# umount function
###############################
function unmount_backup_storage {
    /opt/management/bin/APP_cassandra_mount.sh umount /apl/cassandra_backup ; RC=${?}
    if [[ ${RC} -ne 0 ]] ; then
        log ${RC} "umount ${EXECUTE_HOST} is abnormal end."
        exit 1
    else
        log ${RC} "umount ${EXECUTE_HOST} is success."
    fi
}

###############################
#mount
###############################
function mount_backup_storage {
  /opt/management/bin/APP_cassandra_mount.sh mount "/apl/cassandra_backup" ; RC=${?}
  if [[ ${RC} -ne 0 ]] ; then
      log ${RC} "mount ${EXECUTE_HOST} is abnormal end."
      exit 1
  else
      log ${RC} "mount ${EXECUTE_HOST} is success."
  fi
}

###############################
#send backup server
###############################
function send_archive_to_backup_server {
  find ${CASSANDRA_DATA_DIR} -path "*/snapshots/${SNAPSHOT_NAME}" -print0 | tar -cvz -T - --null -f /tmp/${SNAPSHOT_NAME}.tar.gz ; RC=${?}
  if [[ ${RC} -ne 0 ]] ; then
      log ${RC} "zip ${EXECUTE_HOST} is abnormal end."
      exit 1
  else
      log ${RC} "zip ${EXECUTE_HOST} is success."
  fi

  mv /tmp/${SNAPSHOT_NAME}.tar.gz ${NODE_BACKUP_DIR} ; RC=${?}
  if [[ ${RC} -ne 0 ]] ; then
      log ${RC} "send backup server ${EXECUTE_HOST} is abnormal end."
      exit 1
  else
      log ${RC} "send backup server ${EXECUTE_HOST} is success."
  fi
}

###############################
#generation
###############################
function rotate_archives {
  # コマンドグループ
  {
      if [[ ${TENANT_ID} == ${TENANT_ID_WITH_LEGACY_BACKUP_FILE_FORMAT} ]] ; then
          /bin/find ${NODE_BACKUP_DIR} -maxdepth 1 -name "${BASE_FILE_NAME}_[0-9][0-9][0-9][0-9]*" -or -name "${BASE_FILE_NAME}_${TENANT_ID}_*"
      else
          /bin/find ${NODE_BACKUP_DIR} -maxdepth 1 -name "${BASE_FILE_NAME}_${TENANT_ID}_*"
      fi

  } | xargs ls -t -dF |tail --lines=+$((GENERATION_DAIRY+1)) | xargs -I% rm -rf % ;RC=${?}
  if [[ ${RC} -ne 0 ]] ; then
      log ${RC} "generation ${EXECUTE_HOST} is abnormal end."
      exit 1
  else
      log ${RC} "generation ${EXECUTE_HOST} is success."
  fi
}

###############################
#claer snapshot
###############################
function execute_clear_snapshot {
  local KEYSPACE=$1
  nodetool clearsnapshot "${KEYSPACE}" ; RC=${?}
  if [[ ${RC} -ne 0 ]] ; then
      log ${RC} "delete snapshot ${KEYSPACE} ${EXECUTE_HOST} is abnormal end."
      exit 1
  else
      log ${RC} "delete snapshot ${KEYSPACE} ${EXECUTE_HOST} is success."
  fi
}
###############################
#claer snapshot
###############################
function clear_snapshot {
  for KEYSPACE in ${KEYSPACE_LIST}
  do
      execute_clear_snapshot "${KEYSPACE}"
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
