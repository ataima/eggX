#!/bin/sh 

SCRIPT_DIR=$(pwd)

# include configuration
source "$SCRIPT_DIR/conf.sh"
# include io functions
source "$SCRIPT_DIR/functions.sh"

OREPO=$SCRIPT_DIR/../repo

declare -A MAP    

ALL_PACKETS=$(ls $OREPO )

# if repo non exist create
function check_repository(){
equs $REPO
if [ $? -eq 1 ]; then
error_c "REPO not configured !! Have to set REPO in conf.sh"
fi

if [ ! -d "$REPO" ]; then
mkdir "$REPO"
cp -a "$ROOT/repo/*" "$REPO/."
fi 

if [ ! -d "$SOURCES" ]; then
mkdir "$SOURCES"
fi 

}


# test if exist project <name> from packets list...
# $1 packet name
function check_project(){
local tmp=""
if [[ -n "${MAP[$1]}" ]]; then
	return 1
fi
return 0
}

# verify pgp sign 
#$1 file
#$2 remote file.sig
#$3 project
function check_pgp(){
local RES=0
local KEYS=""
if [ ! -f  $1.sig ]; then 
	wget  --show-progress -q "$2.sig" -O "$1.sig"
	tmp=$( ls -al  "$1.sig"  |  awk  '{print $5}' )
	if [  $tmp -ne 0  ]; then
		KEYS=$(ls $ROOT/keys/*.gpg )
		for i in $KEYS; do
			gpg --verify --keyring "$i" "$1.sig"
			RES=$?
			if [ $RES -eq 2 ]; then 
				continue
			fi
			if [ $RES -eq 1 ]; then 
				RES=99
				break
			fi
			if [ $RES -eq 0 ]; then 
				RES=1
				break
			fi		
		done
		if [ $RES -eq 1 ]; then
			print_c "$GREEN_LIGHT" "   - SIG check source OK" "$YELLOW" $3	
			chmod 444 $1
		else
			print_c "$RED_LIGHT" "   - SIG check source FAIL" "$YELLOW" $3	
			rm -f  "$1.sig"
			rm -f "$1"
		fi
	else
		rm -f  "$1.sig"
	fi
else
print_c "$GREEN_LIGHT" "   - SIG check source OK" "$YELLOW" $3	
fi	
return $RES
}



# verify md5 sum 
#$1 file
#$2 remote file.md5
#$3 project
function check_md5sum(){
local RES=0
if [ ! -f  $1.md5 ]; then 
	wget  --show-progress -q "$2.md5" -O "$1.md5"
	tmp=$( ls -al  "$1.md5"  |  awk  '{print $5}' )
	if [  $tmp -ne 0 ]; then
		local sum=$(md5sum  "$1" | awk '{print $1}')
		local req=$(cat "$1.md5" )
		equs $sum $req
		if [ $? -eq 1 ]; then
			print_c "$GREEN_LIGHT" "   - MD5 check source OK" "$YELLOW" $3
			chmod 444 $1
			RES=1
		else
			print_c "$RED_LIGHT" "   - MD5 check source FAIL" "$YELLOW" $3	 
			rm -f "$1.md5"
			rm -f "$1"
			RES=99
		fi 
	else
		rm -f  "$1.md5"
	fi
else
print_c "$GREEN_LIGHT" "   - MD5 check source OK" "$YELLOW" $3	
fi
return $RES
}

# verify sha1 sum 
#$1 file
#$2 remote file.sha1
#$3 project
function check_sha1sum(){
local RES=0
if [ ! -f  $1.sha1 ]; then
	wget  --show-progress -q "$2.sha1" -O "$1.sha1"
	tmp=$( ls -al  "$1.sha1"  |  awk  '{print $5}' )
	if [  $tmp -ne 0 ]; then
		local sum=$(sha1sum  "$1" | awk '{print $1}')
		local req=$(cat "$1.sha1" )
		equs $sum $req
		if [ $? -eq 1 ]; then
			print_c "$GREEN_LIGHT" "   - SHA1 check source OK" "$YELLOW" $3
			chmod 444 $1
			RES=1
		else
			print_c "$RED_LIGHT" "   - SHA1 check source FAIL" "$YELLOW" $3	
			rm -f "$1.sha1"
			rm -f "$1"
			RES=99
		fi 
	else
		rm -f  "$1.sha1"	
	fi
else
print_c "$GREEN_LIGHT" "   - MD5 check source OK" "$YELLOW" $3
fi
return $RES
}

#$1 filename 
#$2 remote repository
#$3 project
function check_sign(){
local RES=0
local ASIGN="sig md5 sha1"
local i=""
for i in $ASIGN; do
 case $i in
	"sig")
	check_pgp $1 $2 $3
	RES=$?	
	;;
	"md5")
	check_md5sum $1 $2 $3
	RES=$?
	;;
	"sha1")
	check_sha1sum $1 $2 $3
	RES=$?
	;;
	*)
	error_c "Unknow sign " "$i - project : $3"
	;;
esac 
if [ $RES -eq 1 ]; then break; fi
if [ $RES -eq 99 ]; then break; fi
done
return $RES
}


# get a packet from internet
# $1 project name
# $2 link
# $3 filename 
function wget_packet(){
local RES=0
print_c "$GREEN_LIGHT" "   - Download source" "$YELLOW" $i
if [ ! -d  $REPO/$1/logs ]; then 
	mkdir -p  $REPO/$1/logs
fi
local LOG=$(date +%d-%m-%y-%H:%M:%S)-log.txt
local tmp=$(touch $REPO/$1/logs/$LOG)
local PNAME="$2/$3"
rm -f $REPO/$1/logs/$LOG/*
wget  --show-progress -q -o "$REPO/$1/logs/$LOG" "$PNAME" -O "$REPO/$1/$3"
if [ -f  "$REPO/$1/$3" ]; then
	check_sign "$REPO/$1/$3" "$PNAME" "$1"
	RES=$?
	if [ $RES -eq 99 ]; then 
		wget_packet $1 $2 $3
	fi
fi
}


# get a packet from internet
# $1 project name
# $2 link
# $3 filename 
function wget_update_packet(){
local PNAME="$2/$3"
if [ -f  "$REPO/$1/$3" ]; then
	check_sign "$REPO/$1/$3" "$PNAME" "$1"
	RES=$?
	if [ $RES -eq 99 ]; then 
		wget_packet $1 $2 $3
	fi
fi
}

# $1 project name
# $2 link
# $3 filename 
function svn_packet(){
print_c "$GREEN_LIGHT" "   - Svn checkout source" "$YELLOW" $1
local PNAME="$2/$3"
svn   -q co "$PNAME"  "$REPO/$1/$3"
}

# $1 project name
# $2 link
# $3 filename 
function git_packet(){
print_c "$GREEN_LIGHT" "   - Git checkout source" "$YELLOW" $1
local PNAME="$2/$3"
git    co "$PNAME"  "$REPO/$1/$3"
}

# $1 project name
# $2 link
# $3 filename 
function file_packet(){
print_c "$GREEN_LIGHT" "   - File copy source $3" "$YELLOW" $1
local PNAME="$2/$3"
rsync -ry "$PNAME" "$REPO/$1/$3"
if [ $? -ne 0 ]; then
	error_c "Cannot copy file $3" " project $1"
fi
}

#$1 projects
#$2 mode : wget svn git etc
#$3 remote link to download the packet
#$4 packet name 
function download_packet(){
case  $2 in
	"WGET")
	wget_packet $1 $3 $4
	;;
	"GIT")
	git_packet $1 $3 $4
	;;
	"SVN")
	svn_packet $1 $3 $4
	;;
	"FILE")
	file_packet $1 $3 $4
	;;
	*)
	error_c "Unknow method to get sources " "$2 - project : $1"
	;;
esac 
}



#$1 projects
#$2 mode : wget svn git etc
#$3 remote link to download the packet
#$4 packet name 
function is_updated(){
case  $2 in
	"WGET")
	wget_update_packet $1 $3 $4
	;;
	"GIT")
	git_update_packet $1 $3 $4
	;;
	"SVN")
	svn_update_packet $1 $3 $4
	;;
	"FILE")
	file_update_packet $1 $3 $4
	;;
	*)
	error_c "Unknow method to update sources " "$2 - project : $1"
	;;
esac 
}

#$1 projects
#$2 mode : wget svn git etc
#$3 remote link to download the packet
#$4 packet name 
function download_action(){
if [ -f "$REPO/$1/$4" ] ; then 
	is_updated $1 $2 $3 $4
else
	download_packet $1 $2 $3 $4
fi
}



# $1 packet name
function verify_patch(){
local tmp=""
local REMOTE=""
local MODE=""
local PACKET=""
check_project $1
if [ $? -eq 1 ]; then
#exist project name <name> in repo 
#load prj/conf.egg to download the packet
#conf.h REMOTE link packet name md5sum
	if [ -f $REPO/$1/conf.egg ]; then		
		while IFS='' read -r line || [[ -n "$line" ]]; do
			tmp=$(echo  $line | grep PATCH )
			if [ "$tmp" != "" ]; then 
				MODE=$(echo $tmp | awk '{ print $2 }')
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  download mode" "project : $1"
				fi
				REMOTE=$(echo $tmp | awk '{ print $3 }')
				equs "$REMOTE" 
				if [ $? -eq 1 ]; then 
					error_c "Missing remote repository name" "project : $1"
				fi
				PACKET=$(echo $tmp | awk '{ print $4 }')
				equs "$PACKET" 
				if [ $? -eq 1 ]; then 
					error_c "Missing  packet name " "project : $1"
				fi		
				print_c "$GREEN_LIGHT" "   - Download Patch $PACKET" "$YELLOW" $1
				download_action "$1" "$MODE"  "$REMOTE" "$PACKET"
			fi
		done < "$REPO/$1/conf.egg"			
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}


# $1 packet name
function verify_packet(){
local tmp=""
local REMOTE=""
local MODE=""
local PACKET=""
check_project $1
if [ $? -eq 1 ]; then
#exist project name <name> in repo 
#load prj/conf.egg to download the packet
#conf.h REMOTE link packet name md5sum
	if [ -f $REPO/$1/conf.egg ]; then
		tmp=$( cat  $REPO/$1/conf.egg | grep "REMOTE" )
		equs "$tmp"
		if [ $? -eq 1 ]; then 
			error_c "Missing remote repository " "project : $1"
		fi
		MODE=$(echo $tmp | awk '{ print $2 }')
		equs "$MODE"  
		if [ $? -eq 1 ]; then 
			error_c "Missing  download mode" "project : $1"
		fi
		REMOTE=$(echo $tmp | awk '{ print $3 }')
		equs "$REMOTE" 
		if [ $? -eq 1 ]; then 
			error_c "Missing remote repository name" "project : $1"
		fi
		PACKET=$(echo $tmp | awk '{ print $4 }')
		equs "$PACKET" 
		if [ $? -eq 1 ]; then 
			error_c "Missing  packet name " "project : $1"
		fi		
		download_action "$1" "$MODE"  "$REMOTE" "$PACKET"
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}

# download if need source packets
function download_all_packets(){
local i=""
for i in $ALL_PACKETS; do
	print_c "$GREEN_LIGHT" "Source Check for project" "$YELLOW" $i
	verify_packet $i
	verify_patch $i
done	
}




function download_sign_key(){
local KEYS="ftp://ftp.gnu.org/gnu/gnu-keyring.gpg "

if [ ! -d $ROOT/keys ]; then 
	mkdir -p $ROOT/keys
fi

for i in $KEYS; do
	key=$(basename "$i") 
	if [ ! -f "$ROOT/keys/$key" ]; then 
		wget --show-progress -q "$i" -O "$ROOT/keys/$key"
	fi
done
}


# sort list of packets
if [ "$1" == "-D" ]; then 
	set -x
fi
echo $REPO $ROOT $OREPO
for key in $ALL_PACKETS; do MAP[$key]="$key"; done  
rsync -ry $OREPO $ROOT
if [ $? -ne 0 ]; then
	error_c "Cannot work sync repository"
fi
download_sign_key
download_all_packets

