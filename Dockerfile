FROM golang:1.12.6-alpine3.10
MAINTAINER mrclschstr@users.noreply.github.com

RUN echo https://nl.alpinelinux.org/alpine/v3.9/community >> /etc/apk/repositories
RUN apk add --no-cache git nfs-utils openssh fuse
RUN git clone https://github.com/restic/restic \
  && cd restic \
  && go run build.go \
  && cp restic /usr/local/bin/
RUN apk del git

RUN mkdir /mnt/restic

ENV RESTIC_REPOSITORY="/mnt/restic"
ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""
ENV NFS_TARGET=""
ENV BACKUP_CRON="0 */6 * * *"
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""

# /data is the dir where you have to put the data to be backed up
VOLUME /data

COPY backup.sh /bin/backup
RUN chmod +x /bin/backup

COPY entry.sh /entry.sh

RUN touch /var/log/cron.log

WORKDIR "/"

ENTRYPOINT ["/entry.sh"]
