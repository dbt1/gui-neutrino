#!/bin/sh
# script to rebase all branches at once
#
# (C) 2014 Thilo Graf
# License: WTFPLv2
#
# parameters:
# $1 = branch name to which you rebase
# $2 = dryrun
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


for f in  $BRANCHES ; do
	if [[ "$f" != "$1" ]]; then
		if [[ "$f" =~ "$1" ]]; then
			echo "###################################################################################"
			echo -e "try to rebase:\n\033[1;33m[$1] ===== into ===>>> [$f]\033[0m"
			git rebase --abort &>/dev/null
			git checkout $f
			if [[ "$2" == "dryrun" ]]; then
				echo -e "rebase [$1] => [$f]"
			else
				git rebase -v $1
			fi;
			echo -e "ready\n"
		fi;
	fi;
done

git checkout $1	&>/dev/null




