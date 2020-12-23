#!/bin/bash -ex
###################################################
#  Script name  : APP_cassandra_mount.sh
#  Description  : バックアップサーバへのマウント及びアンマウント
#  Server type  : Cassandra
#  User         : reactivejob
#  Usage        :
#  Parameter    : 第1引数(必須)　maunt or umaunt
#  Parameter    : 第2引数 マウントオプション
#  Returns      : 0:正常終了、1:異常終了
###################################################
LOGNAME=/apl/var/log/cassandra/cassandra_backup.log

###############################
# log function
###############################
log() {
    local RC=${1}
    local MSG=${2}

    if [ "${RC}" = "0" ]; then
        local LEVEL=INFO
    else
        local LEVEL=ERROR
    fi

    /bin/echo -e "`date +%Y/%m/%d\ %H:%M:%S`\t`basename $0`\t`whoami`\texit_code:${RC}\t${LEVEL}\t${MSG}" | tee --append ${LOGNAME}
}

###############################
# Preparation
###############################

if [ $# -ne 2 ]; then
   RC=1
   log ${RC} "Argument is missing. Please set 2 argument."
   exit 1
fi

MTYPE=${1}
FSYSTEM=${2}
RC=0

###############################
# Main
###############################

case ${MTYPE} in
   mount  )
      if [ `df | grep -c ${FSYSTEM}` -ne 0 ] ; then
           RC=1
           log ${RC} "[${FSYSTEM}] is already mounted."
         exit 1
      else
         ${MTYPE} ${FSYSTEM} ; RC=${?}
         if [ ${RC} -ne 0 ] ; then
           log ${RC} "[${FSYSTEM}] mount Failed."
         exit 1
         fi
      fi
      ;;
   umount )
      if [ `df | grep -c ${FSYSTEM}` -eq 0 ] ; then
         RC=1
         log ${RC} "[${FSYSTEM}] is already unmounted."
         exit 1
      else
         ${MTYPE} ${FSYSTEM} ; RC=${?}
         if [ ${RC} -ne 0 ] ; then
            log ${RC} "[${FSYSTEM}] unmount Failed."
            exit 1
         fi
      fi
      ;;
   *      )
      RC=1
      log ${RC} "Please input "mount" or "umount""
      exit 1
      ;;
esac

###############################
# Postprocessing
###############################

log ${RC} "[${MTYPE} ${FSYSTEM}] is normal end."

exit 0
