#!/bin/sh
#set -x


FTPLOGIN=$1
FTPPASS=$2
FTPHOST=$3
REMOTEDIR=$4
FILES=$5

ncftp -u $FTPLOGIN -p $FTPPASS $FTPHOST <<EOF
cd ${REMOTEDIR}
rm neutrino
quit
no
EOF


ncftpput -v -u $FTPLOGIN -p $FTPPASS $FTPHOST $REMOTEDIR $FILES








