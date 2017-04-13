#!/bin/sh 

# where is the project eggX
export OROOT="$HOME/eggX"

SCRIPT_DIR=$OROOT/scripts
OREPO=$OROOT/repo/.

# eggX working path default before read general conf.egg
ROOT="$HOME/ebuild"
LOGFILE="$ROOT/log_$(date +%d-%m-%y).txt"
REPO="$ROOT/repo"
SOURCES="$ROOT/sources"
IMAGES="$ROOT/images"
REPOBACKUP="$ROOT/backup"
BUILD="$ROOT/build"
EDITOR="vim"


# include io functions
source "$SCRIPT_DIR/functions.sh"



declare -A MAP    

declare -A BSEQ    
declare -A SORTREQ

ALL_PACKETS=$(ls $OROOT/repo  | sed 's/conf.egg//g')

declare -i MAX_STEP=0


function forcestop(){
	error_c "User Interrupt" " warning work not complete! "
}

trap "forcestop" SIGHUP SIGINT SIGTERM

# test if exist project <name> from packets list...
# $1 packet name
function check_project(){
local tmp=""
if [[ -n "${MAP[$1]}" ]]; then
	return 1
fi
return 0
}


#$1 project
#$2 build phase number 0,1,2.....
function insert_packet(){
local PRI=""
local NAME=""
local INDEX=""
local NUM=0
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action CONFIGURE"	
		xml_count $1 "/egg/project/build"
		NUM=$?
		if [ $NUM -eq 1 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				PRI=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/priority")		
				equs "$PRI"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  build priority Phase $2" "project : $1"
				fi
				NAME=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/name")		
				equs "$NAME"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  build name Phase $2" "project : $1"
				fi 
				
				INDEX="$PRI%$1%$NAME"
				BSEQ[$INDEX]="$INDEX"	
			fi	
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}

#$1 ID BUILD STEP
function prepare_seq_priority(){
local V=""
SORTREQ=""
BSEQ=""
declare -i ID=$1
while [ $ID -lt $MAX_STEP ] ; do
	for V in $ALL_PACKETS; do
		insert_packet $V $ID 
	done	
	ID=$((ID+1))
done
SORTREQ=$(echo ${BSEQ[*]}| tr " " "\n" | sort -n )
}

#set numero massimo di step a disposizone
function get_max_step(){
declare -i NUM=0
declare -i MAX=0
for V in $ALL_PACKETS; do
	xml_count $V "/egg/project/build/step"
	NUM=$?
	if [ $MAX  -lt $NUM ]; then 
		MAX=$NUM
	fi
done
MAX_STEP=$MAX
}

# $1 project
# $2 string array prj names
function check_prj_name(){
local NAME=""
local TT=""
local PRJ_NAME=$2
declare -i IND=0
	xml_count $1 "/egg/project/build"
	IND=$?
	if [ $IND -eq 1 ]; then
		IND=0
		while [  $IND -lt $MAX_STEP ]; do
		NAME=$(xml_value $1 "/egg/project/build/step[@id='$IND']/name")		
		equs "$NAME"  
		if [ $? -eq 1 ]; then 
			error_c "Missing  build name Phase $2" "project : $1"
		else
			TT=$(echo $PRJ_NAME | grep $NAME)
			if [ "$TT" == "" ]; then 
				PRJ_NAME="$PRJ_NAME""  ""$NAME"
			fi
		fi 	
		IND=$((IND+1))		
		done
	fi
echo $PRJ_NAME
}


#print build start 
#$1 pririty
#$2 name
#$3 project
function print_build_msg(){
print_ita  "DO   : $1"  "$2"  "$3"
}


#none
function build_all(){
local ID=0 
local V=""
while [ $ID -lt $MAX_STEP ] ; do
	prepare_seq_priority $ID
	for V in $SORTREQ; do
		V=$(echo $V  | sed -e 's/%/   /g')
		PRI=$(echo $V | awk '{print $1}')
		NAME=$(echo $V | awk '{print $2}')
		PRJ=$(echo $V | awk '{print $3}')
		print_build_msg "$PRI" "$NAME" "$PRJ"
		cd "$BUILD/$PRJ/$NAME"
		$BUILD/$PRJ/$NAME/bootstrap.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		$BUILD/$PRJ/$NAME/build.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		sync
	done
done
}

#none
function compile_all(){
local ID=0 
local V=""
while [ $ID -lt $MAX_STEP ] ; do
	prepare_seq_priority $ID
	for V in $SORTREQ; do
		V=$(echo $V  | sed -e 's/%/   /g')
		PRI=$(echo $V | awk '{print $1}')
		NAME=$(echo $V | awk '{print $2}')
		PRJ=$(echo $V | awk '{print $3}')
		print_build_msg "$PRI" "$NAME" "$PRJ"
		cd "$BUILD/$PRJ/$NAME"
		$BUILD/$PRJ/$NAME/build.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		sync
	done
done
}



#$@ from argv build.sh
function build_single(){
#trovo nomi build per ogni progetto
local V=""
local T=""
local SEQ=""
local PRJ_NAMES=""
for V in $@; do
	PRJ_NAMES=$(check_prj_name "$V" "$PRJ_NAMES")
done

local PWD=$(pwd)
for V in $PRJ_NAMES; do
	for I in $@; do
		for T in $SORTREQ; do
			SEQ=$(echo $T | grep $V | grep $I )
			if [ "$SEQ" != "" ]; then 
				break;
			fi
		done
		SEQ=$(echo $SEQ  | sed -e 's/%/   /g')
		PRI=$(echo $SEQ | awk '{print $1}')
		NAME=$(echo $SEQ | awk '{print $2}')
		PRJ=$(echo $SEQ | awk '{print $3}')
		print_build_msg "$PRI" "$NAME" "$PRJ"
		cd "$BUILD/$V/$I"
		$BUILD/$V/$I/bootstrap.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		$BUILD/$V/$I/build.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		sync
		print_c "$WHITE" "-------------------------------------------------------"
	done 
done
}

#$@ from argv build.sh
function compile_single(){
#trovo nomi build per ogni progetto
local PRJ_NAMES=""
for V in $@; do
	PRJ_NAMES=$(check_prj_name "$V" "$PRJ_NAMES")
done

local PWD=$(pwd)
for V in $PRJ_NAMES; do
	set -x
	for I in $@; do
		for T in $SORTREQ; do
			SEQ=$(echo $T | grep $V | grep $I )
			if [ "$SEQ" != "" ]; then 
				break;
			fi
		done
		SEQ=$(echo $SEQ  | sed -e 's/%/   /g')
		PRI=$(echo $SEQ | awk '{print $1}')
		NAME=$(echo $SEQ | awk '{print $2}')
		PRJ=$(echo $SEQ | awk '{print $3}')
		print_build_msg "$PRI" "$NAME" "$PRJ"
		cd "$BUILD/$V/$I"
		$BUILD/$V/$I/build.sh
		sync
		print_c "$WHITE" "-------------------------------------------------------"
	done 
done
}



#$@
function build_all_packet(){
if [ "$1" == "" ]; then
	build_all
else
	build_single $@
fi
}

#$@
function compile_all_packet(){
if [ "$1" == "" ]; then
	compile_all
else
	compile_single $@
fi
}


#$ARGV TODO
function config_all_step(){
declare -i NUM=0
REX='^[0-9]+$'
if ! [[ $1 =~ $REX ]] ; then
	while [ $NUM -lt $MAX_STEP ]; do 
		$SCRIPT_DIR/configure.sh  $NUM $@
		if [ $? -ne 0 ]; then 
			exit 1
		fi
		NUM=$((NUM+1))
	done
else
	shift
	$SCRIPT_DIR/configure.sh $NUM $@
	if [ $? -ne 0 ]; then 
		exit 1
	fi
fi
}



#$ARGV 
# ex 0 gcc -> try step of project gcc
function try_packet(){
local PRJ=""
local V=""
declare -i NUM=$1
REX='^[0-9]+$'
if ! [[ $NUM =~ $REX ]] ; then
   error_c "Input step isn't a number !!"
fi
if [ ! "$2" ]; then
	error_c "Input missing project  !!"
fi
if [ $NUM -lt $MAX_STEP ]; then
	prepare_seq_priority $NUM
	for i in $SORTREQ; do
		V=$(echo $i  | sed -e 's/%/   /g')
		NAME=$( echo $V | awk '{print $2}' )
		if [ "$NAME" == "$2" ]; then			
			PRJ=$( echo $V | awk '{print $3}' )
			break;
		fi
	done
	V=$(pwd)
	cd "$BUILD/$PRJ/$2"
	bash --init-file $BUILD/$PRJ/$2/setenv.sh
	cd $V	
else
	error_c "Input step too BIG !!"
fi
}

#$ARGV 
#  gcc -> edit conf.egg of project gcc
function edit_packet(){
local PRJ=""
local V=""
if [ ! "$1" ]; then
	error_c "Missing Input project "
fi
check_project "$1"
if [ $? -ne 0 ]; then
	$EDITOR "$OREPO/$1/conf.egg"
else
	error_c "Missing project in $OREPO " "project : $1"
fi
}



function usage(){
	print_c "$BLUE_LIGHT" "usage : ./build.sh <-D> command  <args to pass subcommand>"
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-D or --debug : set debug mode" 
	print_c  "$YELLOW" "COMMAND" "$GREEN" "source : download all sources from repo projects"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "configure : configure all repo projects or specified projects in argv"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "do : configure+build    all repo projects or specified projects in argv"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "build :   build all repo projects or specified projects in argv"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "redoall : clear all build and deploy aout and redo source + configure+do"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "bash <step xx> <project nn>: open a bash with setenv for step xx of project nn"	
	print_c  "$YELLOW" "COMMAND" "$GREEN" "vim <project nn>: edit a conf.egg file of project nn"	
	
	exit 1
}

#$1 build id number
function main(){
local SOURCE=0
local CONFIGURE=0
local MAKE=0
local DO=0
local REDOALL=0
local TRY=0
local VIM=0
for i in $@; do
case $i in 
	-D|--debug)
	export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
	set -x
	dolog "Set Debug ON"
	shift
	;;	
	source)
	SOURCE=1
	shift
	break
	;;
	bash)
	TRY=1
	shift
	break
	;;	
	configure)
	CONFIGURE=1
	shift
	break
	;;	
	vim)
	VIM=1
	shift
	break
	;;	
	build)
	MAKE=1
	shift
	break
	;;	
	do)
	DO=1		
	shift
	break
	;;		
	redoall)
	REDOALL=1		
	shift
	break
	;;	
	*)
	usage
	error_c "Command line" " unknow option $i"
	;;
esac
done

#set log to download
if [ ! -d $ROOT ]; then 
	mkdir -p $ROOT
fi

if ! [ -e $LOGFILE ]; then
	touch "$LOGFILE"
fi

if [ $(wc -c < "$LOGFILE" ) -gt 1000000 ]; then 
	VV=$(wc -l < "$LOGFILE")
	VV=$((VV-VV/3))
	sed -i '1,$VVd' "$LOGFILE" >> "$LOGFILE_temp"
	mv "$LOGFILE_temp" "$LOGFILE"
fi
#sort project in repo to bin search
for key in $ALL_PACKETS; do MAP[$key]="$key"; done  
# sync repo file to build path 
dolog "Force resync work repo"
rsync -ry $OREPO $REPO
if [ $? -ne 0 ]; then
	error_c "Cannot  sync work repository"
fi


get_max_step

if [ $REDOALL -ne 0 ]; then 
	rm -rf $IMAGES
	rm -rf $BUILD	
	$SCRIPT_DIR/sources.sh
	if [ $? -ne 0 ]; then 
		exit 1
	fi
	config_all_step
	build_all_packet
else
	if [ $SOURCE -ne 0 ]; then	
		$SCRIPT_DIR/sources.sh "$@"
	else
		if [ $CONFIGURE -ne 0 ]; then	
			config_all_step "$@"
		else
			if [ $DO -ne 0 ]; then	
				build_all_packet  "$@"
			else
				if [ $MAKE -ne 0 ]; then	
					compile_all_packet  "$@"
				else
					if [ $TRY -ne 0 ]; then	
						try_packet  "$@"
					else
						if [ $VIM -ne 0 ]; then	
							edit_packet  "$@"
						else
							usage
						fi
					fi
				fi
			fi
		fi
	fi
fi
}


main "$@"
