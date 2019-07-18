#!/bin/sh

echo "Starting container ..."

if [ -n "${NFS_TARGET}" ]; then
    echo "Mounting NFS based on NFS_TARGET: ${NFS_TARGET}"
    mount -o nolock -v ${NFS_TARGET} /mnt/restic
fi

restic snapshots > /dev/null 2>&1
if [ $? -gt 0 ]; then
    echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."

    # INFO https://unix.stackexchange.com/questions/325705/why-is-pattern-command-true-useful/325727
    restic init > /dev/null 2>&1
    if [ $? -gt 0 ]; then
        echo "Failed to init the repository: '${RESTIC_REPOSITORY}'"
        exit 1
    fi
else
    echo "Restic repository '${RESTIC_REPOSITORY}' already initialized."
fi

echo "Setup backup cron job with cron expression BACKUP_CRON: ${BACKUP_CRON}"
echo "${BACKUP_CRON} /bin/backup >> /var/log/cron.log 2>&1" > /var/spool/cron/crontabs/root
crond

echo "Container started."
exec "$@"
