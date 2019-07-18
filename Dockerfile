FROM alpine:3.10

RUN echo https://nl.alpinelinux.org/alpine/v3.10/community >> /etc/apk/repositories
RUN apk add --update --no-cache ca-certificates fuse openssh-client nfs-utils

# Get restic executable
ENV RESTIC_VERSION=0.9.5
ADD https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2 /
RUN bzip2 -d restic_${RESTIC_VERSION}_linux_amd64.bz2 \
  && mv restic_${RESTIC_VERSION}_linux_amd64 /bin/restic \
  && chmod +x /bin/restic \
  && mkdir -p /mnt/restic /var/spool/cron/crontabs /var/log \
  && touch /var/log/cron.log

ENV RESTIC_REPOSITORY="/mnt/restic"
ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""
ENV NFS_TARGET=""
ENV BACKUP_CRON="0 */6 * * *"
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""

# /data is the dir where you have to put the data to be backed up
VOLUME /data

COPY backup.sh /bin/backup
COPY entry.sh /entry.sh

WORKDIR "/"
ENTRYPOINT ["/entry.sh"]
CMD ["tail","-fn0","/var/log/cron.log"]
