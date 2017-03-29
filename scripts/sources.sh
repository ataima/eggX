#!/bin/sh 

# include configuration
source "$(pwd)/conf.sh"
# include io functions
source "$(pwd)/functions.sh"

SCRIPT_DIR=$OROOT/scripts
OREPO=$OROOT/repo/.
RKEYS=$OROOT/Keys



declare -A MAP    

ALL_PACKETS=$(ls $ORExml_valuePO )

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
	dolog "Download sign file : $1.sig"
	wget  --show-progress -q "$2.sig" -O "$1.sig"
	tmp=$( ls -al  "$1.sig"  |  awk  '{print $5}' )
	if [  $tmp -ne 0  ]; then
		KEYS=$(ls $RKEYS/*.gpg )
		for i in $KEYS; do
			gpg --verify --keyring "$i" "$1.sig"
			RES=$?
			if [ $RES -eq 2 ]; then 
				continue
			fi
			if [ $RES -eq 1 ]; then 
				dolog "Gpg sign  fail redo download : $1.sig"
				RES=99
				break
			fi
			if [ $RES -eq 0 ]; then 
				dolog "Gpg sign  ok : $1.sig"
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
RES=1
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
	dolog "Download md5 file : $1.md5"
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
RES=1
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
	dolog "Download sha1 file : $1.sha1"
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
print_c "$GREEN_LIGHT" "   - SHA1 check source OK" "$YELLOW" $3
RES=1
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
if [ $RES -eq 1 ] || [ $RES -eq 99 ]; then 
	break
fi
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
dolog "Created download log file : $REPO/$1/logs/$LOG"
wget  --show-progress -q -o "$REPO/$1/logs/$LOG" "$PNAME" -O "$REPO/$1/$3"
if [ -f  "$REPO/$1/$3" ]; then
	check_sign "$REPO/$1/$3" "$PNAME" "$1"
	RES=$?
	if [ $RES -eq 99 ]; then 
		wget_packet $1 $2 $3
	fi
	if [ $RES -eq 1 ]; then 
		if [ ! -d "$SOURCES/$1" ]; then 
			mkdir -p "$SOURCES/$1"
		fi
		dolog "Untar file $REPO/$1/$3 "
		tar -xf "$REPO/$1/$3" -C  "$SOURCES/$1"
		if [ $? -ne 0 ]; then
			error_c "Unable to untar file " "$REPO/$1/$3 project $1"
		fi
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
# $4 password svn
function svn_packet(){
local RPWD=""
print_c "$GREEN_LIGHT" "   - Svn checkout source" "$YELLOW" $1
local PNAME="$2/$3"
if [ ! -d "$SOURCES/$1" ]; then 
	mkdir  -p  "$SOURCES/$1"
fi
if [ "$4" !=  "" ]; then
	RPWD="--non-interactive --password=$4"
fi
svn   -q co $PNAME  $SOURCES/$1 $RPWD
if [ $? -ne 0 ]; then 
	error_c "Svn Checkout error " "   project $1"
fi 
}

# $1 project name
# $2 link
# $3 filename 
# $4 password optional
function svn_update_packet(){
local RPWD=""
print_c "$GREEN_LIGHT" "   - Svn update source" "$YELLOW" $1
local PNAME="$2/$3"
if [ "$4" !=  "" ]; then
	RPWD="--non-interactive --password=$4"
fi
if [ ! -d "$SOURCES/$1" ]; then 
	mkdir  -p "$SOURCES/$1"
	svn   -q co $PNAME  $SOURCES/$1 $RPWD
	if [ $? -ne 0 ]; then 
		error_c "Svn Checkout error " "   project $1"
	fi 
else
	if [ -d ".svn" ]; then 
		local PWD=$(pwd)
		cd "$SOURCES/$1"
		svn   update  $RPWD
		if [ $? -ne 0 ]; then 
			error_c "Svn Update error " "   project $1"
		fi 
		cd "$PWD"
	else
		svn   -q co $PNAME  $SOURCES/$1  $RPWD
		if [ $? -ne 0 ]; then 
			error_c "Svn Checkout error " "   project $1"
		fi 	
	fi
fi
}

# $1 project name
# $2 link
# $3 filename 
function git_packet(){
print_c "$GREEN_LIGHT" "   - Git clone source" "$YELLOW" $1
local PNAME="$2/$3"
if [ ! -d "$SOURCES/$1" ]; then 
	mkdir  -p  "$SOURCES/$1"
fi
git   clone $PNAME  "$SOURCES/$1"
if [ $? -ne 0 ]; then 
	error_c "Git Clone error " "   project $1"
fi 
}

# $1 project name
# $2 link
# $3 filename 
function git_update_packet(){
print_c "$GREEN_LIGHT" "   - Git pull source" "$YELLOW" $1
local PNAME="$2/$3"
local PWD=$(pwd)
if [ ! -d "$SOURCES/$1" ]; then 
	mkdir  -p "$SOURCES/$1"
	git   clone $PNAME  "$SOURCES/$1"
	if [ $? -ne 0 ]; then 
		error_c "Git clone error " "   project $1"
	fi 
else
	cd "$SOURCES/$1"
	git pull origin master
	if [ $? -ne 0 ]; then 
		error_c "Git Update error " "   project $1"
	fi 
	cd "$PWD"
fi
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

# $1 project name
# $2 source path with source created
# $3 filename
apt_packet(){
print_c "$GREEN_LIGHT" "   - File copy source $3" "$YELLOW" $1
local PWD=$(pwd)
rm -rf /tmp/$3
mkdir -p /tmp/$3
cd  /tmp/$3
dolog "Download packet $3 with apt-get"
apt-get source $3
if [ $? -ne  0 ] ; then 
	error_c "apt-get  fail to download source packet" " project $1"
fi
if [ -d $2 ]; then 
	dolog "Copy source from apt-get"
	if [ ! -d "$SOURCES/$1" ]; then
		mkdir -p "$SOURCES/$1"
	fi
	cp -a /tmp/$3/$2/* "$SOURCES/$1"
	if [ $? -ne  0 ] ; then 
		error_c "Cannot copy downloaded source " " project $1"
	fi
fi
cd $PWD
rm -rf /tmp/$3
}

#$1 projects
#$2 mode : wget svn git etc
#$3 remote link to download the packet
#$4 packet name 
#$5 password ssh
function download_packet(){
case  $2 in
	"WGET")
	dolog "Method to get source is : wget for project $1"
	wget_packet $1 $3 $4
	;;
	"GIT")
	dolog "Method to get source is : git for project $1"
	git_packet $1 $3 $4 $5
	;;
	"SVN")
	dolog "Method to get source is : svn for project $1"
	svn_packet $1 $3 $4 $5 
	;;
	"FILE")
	dolog "Method to get source is : rsync for project $1"
	file_packet $1 $3 $4 
	;;
	"APT")
	dolog "Method to get source is : apt-get for project $1"
	apt_packet $1 $3 $4
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
#$5 password ssh
function is_updated(){
case  $2 in
	"WGET")
	wget_update_packet $1 $3 $4
	;;
	"GIT")
	git_update_packet $1 $3 $4 $5
	;;
	"SVN")
	svn_update_packet $1 $3 $4 $5 
	;;
	"FILE")
	file_packet $1 $3 $4
	;;
	"APT")
	;;
	*)
	error_c "Unknow method to update sources " "$2 - project : $1"
	;;
esac 
}



# if present key PASSWORD (svn.. to do ) xx return xx 
function get_password(){
local TPWD="";
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then		
		dolog "Read conf.egg from project $1 : action GET PASSWORD"
		TPWD=$(xml_value $1 '/egg/project/remote/password')
		equs "$TPWD"  
		if [ $? -eq 1 ]; then 
			error_c "Set SSH PASSWORD to null!" "project : $1"
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
echo "$TPWD"
}


#$1 projects
#$2 mode : wget svn git etc
#$3 remote link to download the packet
#$4 packet name 
#$5 action 99=force 1=normal 2=update
function download_action(){
local PWD_SVN=""

if [ "$5" == 99 ]; then	
	if [ -f "$REPO/$1/$4" ]; then 
		dolog "Remove file $REPO/$1/$4 to execute force action"
		rm -f  "$REPO/$1/$4"
	fi
	if [ -d "$SOURCES/$1" ]; then 
		dolog "Remove path $SOURCES/$1 to execute force action"
		rm -rf  "$SOURCES/$1"
	fi
	
fi

# if mode == SVN , GIT test if needed password
if [ "$2" == "SVN" ]; then	 
	PWD_SVN=$(get_password "$1" )
fi

if [ "$2" == "WGET" ]; then 
	if [ -f "$REPO/$1/$4" ] ; then 
		dolog "File $REPO/$1/$4 exist : check sign"
		is_updated $1 $2 $3 $4 
	else
		dolog "Download $REPO/$1/$4 "
		download_packet $1 $2 $3 $4 
	fi
else
	if [ -d "$SOURCES/$1" ] ; then 
		dolog "File $SOURCES/$1 exist : check sign"
		is_updated $1 $2 $3 $4  $PWD_SVN
	else
		dolog "Download $SOURCES/$1 "
		download_packet $1 $2 $3 $4  $PWD_SVN
	fi
fi
}


# $1 packet name
# $2 filename  
function apply_patch(){
local PATCH="$REPO/$1/$2"
local SRC="$SOURCES/$1"
patch -s  --directory="$SRC"  --input="$PATCH"
if [ $? -ne 0 ]; then
	error_c "On apply patch " "   - $2 project $1"
else
	print_c "$GREEN_LIGHT" "   - Apply patch $2" "$YELLOW" $1
fi
}

# $1 packet name
# $2 action 99=force 1=check normal 2=update 
function verify_patch(){
declare -i tmp=0
declare -i i=0
local REMOTE=""
local MODE=""
local PACKET=""
check_project $1
if [ $? -eq 1 ]; then
#exist project name <name> in repo 
#load prj/conf.egg to download the packet
#conf.h REMOTE link packet name md5sum
	if [ -f $REPO/$1/conf.egg ]; then		
		dolog "Read conf.egg from project $1 : action PATCH"
		xml_count $1 "/egg/project/patch"
		tmp=$?
		if [ $tmp -ne 0 ]; then
			while [ $i -le $tmp ]; do
				MODE=$(xml_value $1 "/egg/project/patch[@id='$i']/method")
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  patch download mode" "project : $1"
				fi
				REMOTE=$(xml_value $1 "/egg/project/patch[@id='$i']/url")
				equs "$REMOTE" 
				if [ $? -eq 1 ]; then 
					error_c "Missing patch remote repository name" "project : $1"
				fi
				PACKET=$(xml_value $1 "/egg/project/patch[@id='$i']/file")
				equs "$PACKET" 
				if [ $? -eq 1 ]; then 
					error_c "Missing  patch packet name " "project : $1"
				fi	
				MODE=$(echo $MODE  | tr '[:lower:]' '[:upper:]')
				download_action "$1" "$MODE"  "$REMOTE" "$PACKET" 1
				if [ $2 -eq 99 ]; then 
				apply_patch "$1" "$PACKET"
				fi	
				i=$((i+1))
			done 	
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}



# $1 packet name force skip check update

function download_request(){
local RES=1000
local tmp=""
local MODE=""
check_project $1
if [ $? -eq 1 ]; then
#exist project name <name> in repo 
#load prj/conf.egg to download the packet
#conf.h REMOTE link packet name md5sum
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action DOWNLOAD"
		MODE=$(xml_value $1 "/egg/project/download")
		equs "$MODE"  
		if [ $? -eq 1 ]; then 
			error_c "Missing  download mode" "project : $1"
		fi
		MODE=$(echo "$MODE" | tr '[:lower:]' '[:upper:]')
		 case $MODE in
			"FORCE")
			RES=99	
			;;
			"SKIP")
			RES=0
			;;
			"CHECK")
			RES=1
			;;
			"UPDATE")
			RES=2
			;;
			*)
			error_c "Unknow status Mode " "$MODE - project : $1"
			;;
		esac 
					
		if [  $RES -eq 1000 ]; then
			error_c "Missing DOWNLOAD mode in conf.egg:" " - project : $1"
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
return $RES
}


# $1 packet name
# $2 action 99=force 1=check normal 2=update 
function verify_packet(){
local RES=0
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
		dolog "Read conf.egg from project $1 : action REMOTE"		
		MODE=$(xml_value $1 "/egg/project/remote/method")
		equs "$MODE"  
		if [ $? -eq 1 ]; then 
			error_c "Missing  download mode" "project : $1"
		fi
		REMOTE=$(xml_value $1 "/egg/project/remote/url")
		equs "$REMOTE" 
		if [ $? -eq 1 ]; then 
			error_c "Missing remote repository name" "project : $1"
		fi
		PACKET=$(xml_value $1 "/egg/project/remote/file")
		equs "$PACKET" 
		if [ $? -eq 1 ]; then 
			error_c "Missing  packet name " "project : $1"
		fi		
		MODE=$(echo $MODE  | tr '[:lower:]' '[:upper:]')
		download_action "$1" "$MODE"  "$REMOTE" "$PACKET" "$2"
		RES=1	
		if [ $RES -ne 1 ]; then
			error_c "Missing REMOTE key in conf.egg " "project : $1"
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}

# download if need source packets
function download_all_packets(){
local RES=0
local i=""
for i in $ALL_PACKETS; do
	print_c "$GREEN_LIGHT" "Source Check for project" "$YELLOW" $i
	download_request $i
	RES=$?
	if [ "$RES"  -ne 0 ]; then 
	verify_packet $i $RES
	verify_patch $i $RES
	else
	print_c "$GREEN_LIGHT" "   - SKIP Download STAGE" "$YELLOW" $i	
	fi
done	
}



# $1 requested
function download_sign_key(){
local KEYS="ftp://ftp.gnu.org/gnu/gnu-keyring.gpg "

if [ ! -d $RKEYS ]; then 
	dolog "Create dir for gpg keys"
	mkdir -p $RKEYS
fi
if [ "$1" == "" ]; then
	for i in $KEYS; do
		key=$(basename "$i") 
		if [ ! -f "$RKEYS/$key" ]; then 
			dolog "Download keys from $i"
			wget --show-progress -q "$i" -O "$RKEYS/$key"
			if [ -s "$RKEYS/$key" ]; then
				dolog "Download keys from $i Okey"	
			else		
				rm -f "$RKEYS/$key"
				error_c "Download gpg certificate" "$key"						
			fi
		fi
	done
else
	key=$(basename "$1") 
	if [ ! -f "$RKEYS/$key" ]; then 
		dolog "Download keys from $1"
		wget --show-progress -q "$1" -O "$RKEYS/$key"
		if  [  -s "$RKEYS/$key" ]; then
			dolog "Download keys from $1 Okey"
		else
			rm -f "$RKEYS/$key"
			error_c "Download gpg certificate" "$key"		
		fi
	fi
fi
}

# none 
function check_work_dir(){
#ALL_PACKETS
ALL_PACKETS=$(ls $OROOT/repo)
#ROOT
if [ ! -d "$ROOT" ]; then 
	mkdir -p "$ROOT"
fi
#set log to download
LOGFILE="$LOGFILE""-download.txt"
touch "$LOGFILE"
#REPO
if [ ! -d "$REPO" ]; then 
	dolog "Create $REPO path"
	mkdir -p "$REPO"
fi
#SOURCES
if [ ! -d "$SOURCES" ]; then 
	dolog "Create $SOURCES path"
	mkdir -p "$SOURCES"
fi
#IMAGES
if [ ! -d "$IMAGES" ]; then 
	dolog "Create $IMAGES path"
	mkdir -p "$IMAGES"
fi

}

#$1  projects
#$2   WGET,SVN ...MODE
#$3   DEST file
function patch_reverse_action (){
local PWD=$(pwd)
if [ ! -d $SOURCES/$1 ]; then
	error_c " Missing projects ! " "   - project $1"
fi

cd  $SOURCES/$1

case  $2 in
	"WGET")
	warning_c "wget create a patch not implemented " " - project : $1"
	;;
	"GIT")
	git diff > $3
	;;
	"SVN")
	svn diff > $3
	;;
	"FILE")
	warning_c "file create a patch not implemented " " - project : $1"
	;;
	"APT")
	warning_c "apt create a patch not implemented " " - project : $1"
	;;
	*)
	error_c "Unknow method to create a patch " "$2 - project : $1"
	;;
esac 

cd $PWD
}



# $1 packet name
# $2 dest patch 
function generate_patch(){
local RES=0
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
		dolog "Read conf.egg from project $1 : action REMOTE"
		MODE=$(xml_value $1 "/egg/project/remote/method")
		equs "$MODE"  
		if [ $? -eq 1 ]; then 
			error_c "Missing  download mode" "project : $1"
		fi
		REMOTE=$(xml_value $1 "/egg/project/remote/url")
		equs "$REMOTE" 
		if [ $? -eq 1 ]; then 
			error_c "Missing remote repository name" "project : $1"
		fi
		PACKET=$(xml_value $1 "/egg/project/remote/file")
		equs "$PACKET" 
		if [ $? -eq 1 ]; then 
			error_c "Missing  packet name " "project : $1"
		fi	
		patch_reverse_action "$1" "$MODE"  "$2"
		RES=1
		if [ $RES -ne 1 ]; then
			error_c "Missing REMOTE key in conf.egg " "project : $1"
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}



#$1 project name
function create_patch_packet() {
local DEST="$REPO/$1"
local SOURCE="$SOURCES/$1"
if [ ! -d "$DEST" ]; then
	error_c "missing repo dir for " "  - project $1"
fi
local name="$DEST/$1_"$(date +%d-%m-%y-%H-%M-%S ).patch
generate_patch "$1" "$name"
if [ $? -ne 0 ]; then
	error_c "On create patch from source " "    - project $1"
fi
md5sum "$name" > "$name".md5
if [ $? -ne 0 ]; then
	error_c "On create Md5 sign file " "    - project $1"
fi
print_c "$GREEN_LIGHT" "Done create patch  " "$YELLOW"  " $i"
}


#$1 project name
function backup_packet() {
local DEST="$REPOBACKUP/$1"
local SOURCE="$SOURCES/$1"
if [ ! -d "$DEST" ]; then
	mkdir -p "$DEST"
fi
local name="$DEST/$1_"$(date +%d-%m-%y-%H-%M-%S ).tar.bz2
echo "tar -cjSf ""$name" "$SOURCE" 
tar -cjSf "$name" "$SOURCE"   
if [ $? -ne 0 ]; then
	error_c "On create Tar backup file " "    - project $1"
fi
md5sum "$name" > "$name".md5
if [ $? -ne 0 ]; then
	error_c "On create Md5 sign file " "    - project $1"
fi
print_c "$GREEN_LIGHT" "Done source backup  " "$YELLOW"  " $i"
}


#$@ none or project nn nn nn....
function backup_source() {
if [ ! -d "$BACKUP" ]; then 
	mkdir -p "$BACKUP"
fi

local ALL="$@"
if [  "$ALL" == "" ]; then 
ALL=$(ls "$SOURCES")
fi

for i in $ALL ; do
	print_c "$GREEN_LIGHT" "Create source backup  " "$YELLOW"  " $i"
	backup_packet "$i"
done

}


#$@ none or project nn nn nn....
function create_patch_source() {

local ALL="$@"
if [  "$ALL" == "" ]; then 
ALL=$(ls "$SOURCES")
fi

for i in $ALL ; do
	print_c "$GREEN_LIGHT" "Create patch from source  " "$YELLOW"  " $i"
	create_patch_packet "$i"
done

}


#none
function init(){
check_work_dir
#sort project in repo to bin search
for key in $ALL_PACKETS; do MAP[$key]="$key"; done  
# sync repo file to build path 
dolog "Force resync work repo"
rsync -ry $OREPO $REPO
if [ $? -ne 0 ]; then
	error_c "Cannot  sync work repository"
fi
#download all key to verify sign
download_sign_key
}


function usage(){
	print_c "$BLUE_LIGHT" "usage : ./download.sh <opt> <args>"
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-D or --debug : set debug mode" 
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-F or --force : force download mode, require one args" 
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-G or --gpg : load a key to test gpg sign, require one args" 
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-C or --createpatch : create with svn, git or diff a patch from current source" 
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-B or --backup : create backup of source as pair of <prj>.tar.bz2 <prj>sign" 	
	print_c  "$PURPLE" "ARGS" "$GREEN" "args for options"
	exit 1
}



function main(){
local FORCE=0
local GPG=0
local BACKUP=0
local CPATCH=0
input_arg "$@"
if [ "$OPT_ARGV" != "" ]; then
	for i in $OPT_ARGV; do
	print_c "$GREEN_LIGHT" "Check option " "$YELLOW"  "$i"
	case $i in 
		-D|--debug)
		export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
		set -x
		dolog "Set Debug ON"
		;;
		-F|--force)
		FORCE=99
		;;
		-G|--gpg)
		GPG=1
		;;
		-C|--createpatch)
		CPATCH=1
		;;
		-B|--backup)
		BACKUP=1
		;;
		*)
		usage
		error_c "Command line" " unknow option $i"
		;;
	esac
	done
fi

if [ $FORCE -eq 99 ] && [ "$ARGV" == "" ]; then
	usage
fi

if [ $GPG -eq 1 ] && [ $ARGN -ne 1 ]; then
	usage
fi




if [ "$ARGV" != "" ]; then
	for i in $ARGV; do
	print_c "$GREEN_LIGHT" "argv " "$YELLOW"  "$i"
	done
fi

init 

if [ $GPG -eq 1 ]; then
	download_sign_key "$ARGV"
else
	if [ $BACKUP -eq 1 ]; then
	backup_source "$ARGV"
	else
		if [ $CPATCH -eq 1 ]; then
		create_patch_source "$ARGV"
		else
			if [  $FORCE -eq 0 ]; then
				download_all_packets
			else
				for i in $ARGV; do
					verify_packet $i $FORCE
					verify_patch $i $FORCE
				done 
			fi
		fi
	fi		
fi
}


main "$@"
