#!/bin/sh
#set -x


LOGIN=$1
PW=$2
REMOTEHOST=$3
REMOTEDIR=$4
FILES=$5


ncftpput -v -u $LOGIN -p $PW $REMOTEHOST $REMOTEDIR $FILES




