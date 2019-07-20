#!/bin/sh

lastBackupLogfile="/var/log/backup-last.log"
lastMailLogfile="/var/log/mail-last.log"
rm -f ${lastBackupLogfile} ${lastMailLogfile}

outputAndLog() {
    echo "$1"
    echo "$1" >> ${lastBackupLogfile}
}

start=`date +%s`
outputAndLog "Starting at $(date +"%Y-%m-%d %H:%M:%S")"
outputAndLog "BACKUP_CRON: ${BACKUP_CRON}"
outputAndLog "RESTIC_TAG: ${RESTIC_TAG}"
outputAndLog "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
outputAndLog "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS}"
outputAndLog "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
outputAndLog "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"

restic backup /data ${RESTIC_JOB_ARGS} --tag=${RESTIC_TAG?"Missing environment variable RESTIC_TAG"} >> ${lastBackupLogfile} 2>&1
if [ $? -eq 0 ]; then
    outputAndLog "Backup successfully finished."
else
    outputAndLog "Backup FAILED. Check ${lastBackupLogfile} for further information."
    restic unlock
    kill 1
fi

if [ -n "${RESTIC_FORGET_ARGS}" ]; then
    outputAndLog "Forget about old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"

    restic forget ${RESTIC_FORGET_ARGS} >> ${lastBackupLogfile} 2>&1
    if [ $? -eq 0 ]; then
        outputAndLog "Forget successfully finished."
    else
        outputAndLog "Forget FAILED. Check ${lastBackupLogfile} for further information."
        restic unlock
    fi
fi

end=`date +%s`
outputAndLog "Finished at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

if [ -n "${MAILX_ARGS}" ]; then
    sh -c "mailx -v -S sendwait ${MAILX_ARGS} < ${lastBackupLogfile} > ${lastMailLogfile} 2>&1"
    if [ $? -eq 0 ]; then
        outputAndLog "Mail notification successfully sent."
    else
        outputAndLog "Sending mail notification FAILED. Check ${lastMailLogfile} for further information."
    fi
fi
