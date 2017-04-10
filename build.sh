#!/bin/sh 

# where is the project eggX
export OROOT="$HOME/eggX"

SCRIPT_DIR=$OROOT/scripts
OREPO=$OROOT/repo/.

# include configuration
source "$SCRIPT_DIR/conf.sh"
# include io functions
source "$SCRIPT_DIR/functions.sh"




declare -A MAP    

declare -A BSEQ    
declare -A SORTREQ

ALL_PACKETS=$(ls $OROOT/repo  | sed 's/conf.egg//g')

declare -i MAX_STEP=0

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
SORTREQ=""
BSEQ=""
while [ $ID -lt $MAX_STEP ] ; do
	for V in $ALL_PACKETS; do
		insert_packet $V $1 
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
		print_c "$WHITE" "-------------------------------------------------------"
		print_c "$GREEN_LIGHT" "$PRI" "$WHITE" "$NAME" "$RED_LIGHT" "$PRJ"
		cd "$BUILD/$PRJ/$NAME"
		$BUILD/$PRJ/$NAME/bootstrap.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		$BUILD/$PRJ/$NAME/build.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		$BUILD/$PRJ/$NAME/install.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		sync
		print_c "$WHITE" "-------------------------------------------------------"
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
		print_c "$WHITE" "-------------------------------------------------------"
		print_c "$GREEN_LIGHT" "$PRI" "$WHITE" "$NAME" "$RED_LIGHT" "$PRJ"
		cd "$BUILD/$PRJ/$NAME"
		$BUILD/$PRJ/$NAME/build.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		sync
		print_c "$WHITE" "-------------------------------------------------------"
	done
done
}

#none
function install_all(){
local ID=0 
local V=""
while [ $ID -lt $MAX_STEP ] ; do
	prepare_seq_priority $ID
	for V in $SORTREQ; do
		V=$(echo $V  | sed -e 's/%/   /g')
		PRI=$(echo $V | awk '{print $1}')
		NAME=$(echo $V | awk '{print $2}')
		PRJ=$(echo $V | awk '{print $3}')
		print_c "$WHITE" "-------------------------------------------------------"
		print_c "$GREEN_LIGHT" "$PRI" "$WHITE" "$NAME" "$RED_LIGHT" "$PRJ"
		cd "$BUILD/$PRJ/$NAME"
		$BUILD/$PRJ/$NAME/install.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		sync
		print_c "$WHITE" "-------------------------------------------------------"
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
		print_c "$WHITE" "-------------------------------------------------------"
		print_c "$GREEN_LIGHT" "$PRI" "$WHITE" "$NAME" "$RED_LIGHT" "$PRJ"
		cd "$BUILD/$V/$I"
		$BUILD/$V/$I/bootstrap.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		$BUILD/$V/$I/build.sh
		if [ $? -ne 0 ] ; then
			exit -1;
		fi
		$BUILD/$V/$I/install.sh
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
		print_c "$WHITE" "-------------------------------------------------------"
		print_c "$GREEN_LIGHT" "$PRI" "$WHITE" "$NAME" "$RED_LIGHT" "$PRJ"
		cd "$BUILD/$V/$I"
		$BUILD/$V/$I/build.sh
		sync
		print_c "$WHITE" "-------------------------------------------------------"
	done 
done
}

#$@ from argv build.sh
function install_single(){
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
		print_c "$WHITE" "-------------------------------------------------------"
		print_c "$GREEN_LIGHT" "$PRI" "$WHITE" "$NAME" "$RED_LIGHT" "$PRJ"
		cd "$BUILD/$V/$I"
		$BUILD/$V/$I/install.sh
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

#$ARGV
function install_all_packet(){
if [ "$1" == "" ]; then
	install_all
else
	isntall_single $@
fi
}

#$ARGV TODO
function config_all_step(){
declare -i NUM=0
while [ $NUM -lt $MAX_STEP ]; do 
	$SCRIPT_DIR/configure.sh $NUM $@
	if [ $? -ne 0 ]; then 
		exit 1
	fi
	NUM=$((NUM+1))
done
}

function usage(){
	print_c "$BLUE_LIGHT" "usage : ./build.sh <-D> command  <args to pass subcommand>"
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-D or --debug : set debug mode" 
	print_c  "$YELLOW" "COMMAND" "$GREEN" "source : download all sources from repo projects"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "configure : configure all repo projects or specified projects in argv"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "do : configure+build+install    all repo projects or specified projects in argv"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "build :   build all repo projects or specified projects in argv"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "install : install   all repo projects or specified projects in argv"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "redoall : clear all build and deploy aout and redo source + configure+do"
	exit 1
}

#$1 build id number
function main(){
local SOURCE=0
local CONFIGURE=0
local MAKE=0
local DO=0
local INSTALL=0
local REDOALL=0
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
	configure)
	CONFIGURE=1
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
	install)
	INSTALL=1		
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
LOGFILE="$LOGFILE""-do.txt"
touch "$LOGFILE"
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
					if [ $INSTALL -ne 0 ]; then	
						install_all_packet  "$@"
					else
						usage
					fi
				fi
			fi
		fi
	fi
fi
}


main "$@"
