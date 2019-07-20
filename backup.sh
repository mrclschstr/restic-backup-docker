#!/bin/sh

# Define and reset logfile
lastLogfile="/var/log/backup-last.log"
rm -f ${lastLogfile}

outputAndLog() {
    echo "$1"
    echo "$1" >> ${lastLogfile}
}

start=`date +%s`
outputAndLog "Starting at $(date +"%Y-%m-%d %H:%M:%S")"
outputAndLog "BACKUP_CRON: ${BACKUP_CRON}"
outputAndLog "RESTIC_TAG: ${RESTIC_TAG}"
outputAndLog "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
outputAndLog "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS}"
outputAndLog "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
outputAndLog "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"

# Do not save full backup log to logfile but to backup-last.log
restic backup /data ${RESTIC_JOB_ARGS} --tag=${RESTIC_TAG?"Missing environment variable RESTIC_TAG"} >> ${lastLogfile} 2>&1
if [ $? -eq 0 ]; then
    outputAndLog "Backup successfully finished."
else
    outputAndLog "Backup FAILED with status ${rc}."
    restic unlock
    kill 1
fi

if [ -n "${RESTIC_FORGET_ARGS}" ]; then
    outputAndLog "Forget about old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"

    restic forget ${RESTIC_FORGET_ARGS} >> ${lastLogfile} 2>&1
    if [ $? -eq 0 ]; then
        outputAndLog "Forget successfully finished."
    else
        outputAndLog "Forget FAILED with status ${rc}."
        restic unlock
    fi
fi

end=`date +%s`
outputAndLog "Finished at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

if [ -n "${MAILX_ARGS}" ]; then
    mailx -S sendwait ${MAILX_ARGS} < ${lastLogfile} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        outputAndLog "Mail notification successfully sent."
    else
        outputAndLog "Sending mail notification FAILED. Please check your SMTP configuration!"
    fi
fi
