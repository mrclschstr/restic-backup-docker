# Restic Backup Docker Container
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

```
docker pull mrclschstr/restic-backup-docker
```

To enter your container execute:

```
docker exec -ti <your-container-name> /bin/sh
```

Now you can use restic [as documented](https://restic.readthedocs.io/en/stable/Manual/), e.g. try to run `restic snapshots` to list all your snapshots.

# Logfiles
Logfiles are inside the container. If needed you can create volumes for them.

```
docker logs
```
Shows `/var/log/cron.log`

Additionally you can see the the full log, including restic output, of the last execution in `/var/log/backup-last.log`.

# Customize the Container

The container is setup by setting [environment variables](https://docs.docker.com/engine/reference/run/#/env-environment-variables) and [volumes](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems).

## Environment variables

* `RESTIC_REPOSITORY` - the location of the restic repository. Default `/mnt/restic`. For S3: `s3:https://s3.amazonaws.com/BUCKET_NAME`
* `RESTIC_PASSWORD` - the password for the restic repository. Will also be used for restic init during first start when the repository is not initialized.
* `RESTIC_TAG` - Optional. To tag the images created by the container.
* `NFS_TARGET` - Optional. If set the given NFS is mounted, i.e. `mount -o nolock -v ${NFS_TARGET} /mnt/restic`. `RESTIC_REPOSITORY` must remain it's default value!
* `BACKUP_CRON` - A cron expression to run the backup. Note: cron daemon uses UTC time zone. Default: `0 */6 * * *` aka every 6 hours.
* `RESTIC_FORGET_ARGS` - Optional. Only if specified `restic forget` is run with the given arguments after each backup. Example value: `-e "RESTIC_FORGET_ARGS=--prune --keep-last 10 --keep-hourly 24 --keep-daily 7 --keep-weekly 52 --keep-monthly 120 --keep-yearly 100"`
* `RESTIC_JOB_ARGS` - Optional. Allows to specify extra arguments to the back up job such as limiting bandwith with `--limit-upload` or excluding file masks with `--exclude`.
* `AWS_ACCESS_KEY_ID` - Optional. When using restic with AWS S3 storage.
* `AWS_SECRET_ACCESS_KEY` - Optional. When using restic with AWS S3 storage.

## Volumes

* `/data` - This is the data that gets backed up. Just [mount](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems) it to wherever you want.

## Set the hostname

Since restic saves the hostname with each snapshot and the hostname of a docker container is it's id you might want to customize this by setting the hostname of the container to another value.

Either by setting the [environment variable](https://docs.docker.com/engine/reference/run/#env-environment-variables) `HOSTNAME` or with `--hostname` in the [network settings](https://docs.docker.com/engine/reference/run/#network-settings)

## Backup to SFTP

Since restic needs a **password less login** to the SFTP server make sure you can do `sftp user@host` from inside the container. If you can do so from your host system, the easiest way is to just mount your `.ssh` folder conaining the authorized cert into the container by specifying `-v ~/.ssh:/root/.ssh` as argument for `docker run`.

Now you can simply specify the restic repository to be an [SFTP repository](https://restic.readthedocs.io/en/stable/Manual/#create-an-sftp-repository).

```
-e "RESTIC_REPOSITORY=sftp:user@host:/tmp/backup"
```

# TODO

 - Use tags for official releases and not just the master branch
 - Provide simple docker run examples in README
 - Include cronjob for regular restic repository checks (`restic check`)
 - Implement mail notifications for certain events (successfull/failed backups, inconsistent repository, ...) &#8594; see [#3](https://github.com/mrclschstr/restic-backup-docker/issues/3)
