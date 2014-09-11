#!/bin/sh
# script to rebase all branches at once
#
# (C) 2014 Thilo Graf
# License: WTFPLv2
#
# parameters:
# $1 = branch name to which you rebase
#

# Note: It's important that your lokal branches have a canonical name structure, see examples!

#--------------------------------------------------------------------------------------------
#example 1:

#./rebase2.sh master

#this do rebase branch master into all branches with prefix master

# master.prepare
# master.topic1
# master.prepare.topic2
# master.prepare.topic3

#--------------------------------------------------------------------------------------------
#example 2:

#./rebase2.sh master.prepare

#this do rebase branch master.prepare into all branches with prefix master.prepare

# master.prepare
# master.prepare.topic2
# master.prepare.topic3


BASEPATH=`pwd`
cd $BASEPATH

BRANCHES=`git branch`

echo "$BASEPATH"

for f in  $BRANCHES ; do
	if [[ "$f" != "$1" ]]; then
		if [[ "$f" =~ "$1" ]]; then
			echo "###################################################################################"
			echo -e "try to rebase:\n\033[1;33m[$1] ===== into ===>>> [$f]\033[0m"
			git rebase --abort &>/dev/null
			git checkout $f
			git rebase $1
			echo -e "\n"
		fi;
	fi;
done

git checkout $1	&>/dev/null
echo -e "ready\n"



