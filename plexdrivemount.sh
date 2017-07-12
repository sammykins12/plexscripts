#!/bin/bash
# Google Drive Mounting Script v0.5
# This script is designed to run every 10 minutes to check if both Plexdrive and UnionFS are running
# If they are not running it will restart the services

# Global VARS
LOGFILE=/mnt/user/unionfs/log/plexdrive-$(date "+%Y-%m-%d").log
MPOINT=/mnt/user/unionfs/gsuite-remote
PLEXDRIVE=/mnt/disks/appdata/plexdrive/plexdrive
REMOTE=/mnt/user/unionfs/gsuite-remote/
CACHE=/mnt/user/unionfs/gsuite-cache
LOCAL=/mnt/user/unionfs/gsuite-local/
UNION=/mnt/user/unionfs/backup
# Mount Plexdrive
echo "Starting the Plexdrive Script" >> "$LOGFILE" 2>&1

# Unmount if mounted

if [[ $1 = "unmount" ]]; then
    echo "Unmounting $MPOINT"
    fusermount -uz $REMOTE
	fusermount -uz $UNION
    exit
fi

# Check if mountpoint exists, then continue

if mountpoint -q $MPOINT ; then
    echo "$MPOINT already mounted"
else
    echo "Mounting $MPOINT"
	#Unmount any stuck mounts
	fusermount -uz $REMOTE
	fusermount -uz $UNION
	#Mount Plexdrive
    $PLEXDRIVE -m localhost -c /mnt/disks/appdata/plexdrive/ -t $CACHE $REMOTE -o allow_other -v 2 &>>$LOGFILE &
	#Restart Plex Docker after mount
	docker restart plex
fi

# Check if UnionFS is running, if not, start

case "$(pidof unionfs | wc -w)" in

'0')  echo "Restarting UnionFS"
    /usr/bin/unionfs -o cow $LOCAL=RW:$REMOTE=RO $UNION -o allow_other -o nonempty &
    ;;
'1')  echo "UnionFS already running"
    ;;
esac