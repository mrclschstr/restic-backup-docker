# Restic Backup Docker Container

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/mrclschstr/restic-backup-docker.svg) ![Docker Pulls](https://img.shields.io/docker/pulls/mrclschstr/restic-backup-docker.svg) ![Docker Stars](https://img.shields.io/docker/stars/mrclschstr/restic-backup-docker.svg)

A docker container to automate [restic backups](https://restic.github.io/). This container runs restic backups in regular intervals. 

* Easy setup and maintanance
* Support for different targets (currently: Local, NFS, SFTP)
* Support `restic mount` inside the container to browse the backup files

**Container**: [mrclschstr/restic-backup-docker](https://hub.docker.com/r/mrclschstr/restic-backup-docker)

Please don't hesitate to report any issue you find. **Thanks.**

## Credits

This docker container is based on the work of [lobaro/restic-backup-docker](https://github.com/lobaro/restic-backup-docker) and [Cobrijani/restic-backup-docker](https://github.com/Cobrijani/restic-backup-docker). Big shoutout and thanks for your groundwork!

## Why this fork?

At the moment (July 2019) the container [lobaro/restic-backup-docker](https://github.com/lobaro/restic-backup-docker) is based on busybox and therefore backups to SFTP don't work anymore (see [#27](https://github.com/lobaro/restic-backup-docker/issues/27)). I forked the project and use the [alpine v3.10](https://hub.docker.com/_/alpine) container as a basis. The container is a little bit bigger now (~20 MB compared to 10 MB), but backups to a SFTP target are working again.

# Quick Setup

To use this container just use the following docker command on your shell:

```console
docker pull mrclschstr/restic-backup-docker
```

To enter your container execute:

```console
docker exec -ti <your-container-name> /bin/sh
```

Now you can use restic [as documented](https://restic.readthedocs.io/en/stable/Manual/), e.g. try to run `restic snapshots` to list all your snapshots.

# Logfiles

Logfiles are inside the container. If needed you can create volumes for them. The command `docker logs` shows `/var/log/cron.log`.

Additionally you can see the the full log, including restic output, of the last execution in `/var/log/backup-last.log`.

# Customize the Container

The container is setup by setting [environment variables](https://docs.docker.com/engine/reference/run/#/env-environment-variables) and [volumes](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems).

## Environment variables

|  Docker Environment Variable |  Mandatory |  Default      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|------------------------------|------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RESTIC_REPOSITORY`          | Yes        | `/mnt/restic` | The location of the restic repository. For S3: `s3:https://s3.amazonaws.com/BUCKET_NAME`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `RESTIC_PASSWORD`            | Yes        | *empty*       | The password for the restic repository. Will also be used for restic init during first start when the repository is not initialized.                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `RESTIC_TAG`                 | No         | *empty*       | To tag the images created by the container.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `NFS_TARGET`                 | No         | *empty*       | If set the given NFS is mounted, i.e. `mount -o nolock -v ${NFS_TARGET} /mnt/restic`, `RESTIC_REPOSITORY` must remain it's default value!                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `BACKUP_CRON`                | No         | `0 */6 * * *` | A cron expression to run the backup. **Note:** cron daemon uses UTC time zone.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `RESTIC_FORGET_ARGS`         | No         | *empty*       | Only if specified `restic forget` is run with the given arguments after each backup. Example value: `-e "RESTIC_FORGET_ARGS=--prune --keep-last 10 --keep-hourly 24 --keep-daily 7 --keep-weekly 52 --keep-monthly 120 --keep-yearly 100"`.                                                                                                                                                                                                                                                                                                                       |
| `RESTIC_JOB_ARGS`            | No         | *empty*       | Allows to specify extra arguments to the back up job such as limiting bandwith with `--limit-upload` or excluding file masks with `--exclude`.                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `AWS_ACCESS_KEY_ID`          | No         | *empty*       | When using restic with AWS S3 storage.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `AWS_SECRET_ACCESS_KEY`      | No         | *empty*       | When using restic with AWS S3 storage.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `MAILX_ARGS`                 | No         | *empty*       | If specified, the content of `/var/log/backup-last.log` is sent via mail after each backup using an *external SMTP*. To have maximum flexibility, you have to specify the mail/smtp parameters by your own. Have a look at the [mailx manpage](https://linux.die.net/man/1/mailx) for further information. Example value: `-e "MAILX_ARGS=-r 'from@example.de' -s 'Result of the last restic backup run' -S smtp='smtp.example.com:587' -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user='username' -S smtp-auth-password='password' 'to@example.com'"`. |

## Volumes

* `/data` - This is the data that gets backed up. Just [mount](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems) it to wherever you want.

## Set the hostname

Since restic saves the hostname with each snapshot and the hostname of a docker container is it's id you might want to customize this by setting the hostname of the container to another value.

Either by setting the [environment variable](https://docs.docker.com/engine/reference/run/#env-environment-variables) `HOSTNAME` or with `--hostname` in the [network settings](https://docs.docker.com/engine/reference/run/#network-settings)

## Cron time and timezone

The cron daemon uses UTC time zone by default. You can map the files `/etc/localtime` and `/etc/timezone` read-only to the container to match the time and timezone of your host.

```console
-v /etc/localtime:/etc/localtime:ro \
-v /etc/timezone:/etc/timezone:ro
```

## Backup to SFTP

Since restic needs a **password less login** to the SFTP server make sure you can do `sftp user@host` from inside the container. If you can do so from your host system, the easiest way is to just mount your `.ssh` folder conaining the authorized cert into the container by specifying `-v ~/.ssh:/root/.ssh` as argument for `docker run`.

Now you can simply specify the restic repository to be an [SFTP repository](https://restic.readthedocs.io/en/stable/Manual/#create-an-sftp-repository).

```console
-e "RESTIC_REPOSITORY=sftp:user@host:/tmp/backup"
```

# TODO

 - Use tags for official releases and not just the master branch
 - Provide simple docker run examples in README
 - Include cronjob for regular restic repository checks (`restic check`)
