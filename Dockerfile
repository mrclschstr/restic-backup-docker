FROM golang:1.12.6-alpine3.10

RUN echo https://nl.alpinelinux.org/alpine/v3.10/community >> /etc/apk/repositories
RUN apk add --update --no-cache ca-certificates fuse openssh-client git nfs-utils
RUN git clone https://github.com/restic/restic \
  && cd restic \
  && go run build.go \
  && cp restic /usr/local/bin/ \
  && cd .. \
  && rm -rf restic
RUN apk del git

RUN mkdir /mnt/restic

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
RUN chmod +x /bin/backup
COPY entry.sh /entry.sh

RUN touch /var/log/cron.log

WORKDIR "/"

ENTRYPOINT ["/entry.sh"]
