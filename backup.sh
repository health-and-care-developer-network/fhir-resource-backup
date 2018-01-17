#!/bin/sh

if [ -z $FILENAME ]
then
  FILENAME="PROFILE-BACKUP-$(date +%F).zip"
fi

if [ -z $BACKUP_DIR_NAME ]
then
  BACKUP_DIR_NAME="file-profile-backups"
fi

mkdir -p /backups/$BACKUP_DIR_NAME
echo "Backing up all FHIR profiles to: /backups/$BACKUP_DIR_NAME/$FILENAME"

if [ -f /backups/$BACKUP_DIR_NAME/$FILENAME ]
then
    echo "Backup file already exists with that name - aborting!"
    exit 1
else
    echo "Backing up FHIR profiles"
    zip -r /backups/$BACKUP_DIR_NAME/$FILENAME /source
    EXITSTATUS=$?
    echo "Process complete"
    #exit $EXITSTATUS
fi

# Now, delete all but the most recent 30 backups
echo "Removing old backups"
cd /backups/$BACKUP_DIR_NAME/
ls -tp | grep -v '/$' | tail -n +31 | xargs -I {} rm -- {}
echo "Backups older than the most recent 30 have been deleted"

