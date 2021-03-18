#!/bin/bash
###################################################
#  Script name  : APP_cassandra_backup_execute.sh
#  Description  : cassandraのバックアップとNFSマウントshellを実行する
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
readonly NODE_BACKUP_DIR=/apl/cassandra_backup
readonly SSH_USER='reactivejob'
readonly GENERATION_DAIRY=3
readonly BASE_FILE_NAME=cassandra
readonly CASSANDRA_DATA_DIR=/var/lib/cassandra/data
readonly TENANT_ID_WITH_LEGACY_BACKUP_FILE_FORMAT=""

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
  local USER=$(whoami)
  if [[ ${USER} != ${SSH_USER} ]] ; then
      RC=1
      log ${RC} "please execute job with user : ${SSH_USER} !![${USER}]"
      exit 1
  fi
}

###############################
#check tenant id
###############################
function parse_arguments() {
    if [[ $# -lt 3 ]] ; then
      RC=1
      log ${RC} "Missed parameter, please give TENANT_ID, KEYSPACE_LIST and EXECUTE_HOST for backup."
      exit 1
    fi
    if [[ $# -gt 3 ]] ; then
      RC=1
      log ${RC} "Too many parameters, only three parameters needed."
      exit 1
    fi

    readonly TENANT_ID="$1"
    log ${RC} "TENANT_ID:$TENANT_ID"
    # Get keyspaces from config file
    readonly KEYSPACE_LIST="$2"
    log ${RC} "KEYSPACE_LIST:${KEYSPACE_LIST[@]}"
    # IP of execute host
    readonly EXECUTE_HOST="$3"
    log ${RC} "EXECUTE_HOST:$EXECUTE_HOST"
    # Setting SNAPSHOT_NAME with tenant_id
    readonly SNAPSHOT_NAME_BASIC="${BASE_FILE_NAME}_${TENANT_ID}_${EXECUTE_HOST}"
    readonly SNAPSHOT_NAME="${SNAPSHOT_NAME_BASIC}_$(date '+%Y%m%d_%H%M%S')"
}

###############################
#main
###############################
function main {
  validate_user
  RC=0
  parse_arguments "$@"
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
    /opt/management/bin/APP_cassandra_mount.sh umount "/apl/cassandra_backup" ; RC=${?}
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
  find ${CASSANDRA_DATA_DIR} -path "*/snapshots/${SNAPSHOT_NAME}" -print0 | tar --null -cvz -T - -f /tmp/${SNAPSHOT_NAME}.tar.gz ; RC=${?}
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
  {
      if [[ ${TENANT_ID} == "${TENANT_ID_WITH_LEGACY_BACKUP_FILE_FORMAT}" ]] ; then
          /bin/find ${NODE_BACKUP_DIR} -maxdepth 1 -name "${BASE_FILE_NAME}_[0-9][0-9][0-9][0-9]*" -or -name "${SNAPSHOT_NAME_BASIC}_*"
      else
          /bin/find ${NODE_BACKUP_DIR} -maxdepth 1 -name "${SNAPSHOT_NAME_BASIC}_*"
      fi

  } | \
    xargs ls -t -dF | \
    tail --lines=+$((GENERATION_DAIRY+1)) | \
    xargs -I% rm -rf % ;RC=${?}
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
