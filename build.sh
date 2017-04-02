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

ALL_PACKETS=$(ls $OROOT/repo)

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
#trovo nomi build per ogni progetto
local PRJ_NAMES=""
for V in $ALL_PACKETS; do
	PRJ_NAMES=$(check_prj_name "$V" "$PRJ_NAMES")
done

local PWD=$(pwd)
for V in $PRJ_NAMES; do
	cd "$BUILD/$V"
	"$BUILD/$V/main_configure.sh"
	if [ $? -ne 0 ] ; then
		exit -1;
	fi
	"$BUILD/$V/main_build.sh all"
	if [ $? -ne 0 ] ; then
		exit -1;
	fi
	"$BUILD/$V/main_build.sh install"
	if [ $? -ne 0 ] ; then
		exit -1;
	fi
done
}





#$1 force 0=0ff 99 0=on
function build_all_packet(){
if [ "$1" == "" ]; then
	build_all
else
	shift 
	#build $@
fi
}

function config_all_step(){
declare -i NUM=0
while [ $NUM -lt $MAX_STEP ]; do
	bash $SCRIPT_DIR/configure.sh $NUM $@
	NUM=$((NUM+1))
done
}

function usage(){
	print_c "$BLUE_LIGHT" "usage : ./build.sh <-D> command  <args to pass subcommand>"
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-D or --debug : set debug mode" 
	print_c  "$YELLOW" "COMMAND" "$GREEN" "source : download all sources from repo projects"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "configure : configure all repo projects"
	print_c  "$YELLOW" "COMMAND" "$GREEN" "do : build and install  all repo projects"
	exit 1
}

#$1 build id number
function main(){
local SOURCE=0
local CONFIGURE=0
local MAKE=0
input_arg "$@"
if [ "$OPT_ARGV" != "" ]; then
	for i in $OPT_ARGV; do
	print_c "$GREEN_LIGHT" "Check option " "$YELLOW"  "$i"
	case $i in 
		-D|--debug)
		export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
		set -x
		dolog "Set Debug ON"
		shift
		;;		
		*)
		usage
		error_c "Command line" " unknow option $i"
		;;
	esac
	done
fi



if [ "$ARGV" != "" ]; then
	for i in $ARGV; do
	print_c "$GREEN_LIGHT" "Check args " "$YELLOW"  "$i"
	case $i in 
		source)
		SOURCE=1
		shift
		;;	
		configure)
		CONFIGURE=1
		shift
		;;	
		do)
		MAKE=1
		shift
		;;	
		*)
		usage
		error_c "Command line" " unknow option $i"
		;;
	esac
	done
fi

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
if [ $SOURCE -ne 0 ]; then	
	bash $SCRIPT_DIR/sources.sh $@
else
	if [ $CONFIGURE -ne 0 ]; then	
		config_all_step
	else
		if [ $MAKE -ne 0 ]; then	
			build_all_packet  $@
		else
			usage
		fi
	fi
fi
}


main "$@"