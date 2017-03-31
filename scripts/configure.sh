#!/bin/sh 

# include configuration
source "$(pwd)/conf.sh"
# include io functions
source "$(pwd)/functions.sh"


SCRIPT_DIR=$OROOT/scripts
OREPO=$OROOT/repo/.

declare -A MAP    

declare -A BSEQ    
declare -A SORTREQ

ALL_PACKETS=$(ls $OROOT/repo)


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
local ARCH=""
local CROSS=""
local INDEX=""
local NUM=0
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action CONFIGURE"	
		xml_count $1 "/egg/project/build/step[@id='$2']"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			PRI=$(xml_value $1 "/egg/project/build/step[@id='$2']/priority")		
			equs "$PRI"  
			if [ $? -eq 1 ]; then 
				error_c "Missing  build priority Phase $2" "project : $1"
			fi
			NAME=$(xml_value $1 "/egg/project/build/step[@id='$2']/name")		
			equs "$NAME"  
			if [ $? -eq 1 ]; then 
				error_c "Missing  build name Phase $2" "project : $1"
			fi
			ARCH=$(xml_value $1 "/egg/project/build/step[@id='$2']/arch")		
			equs "$ARCH"  
			if [ $? -eq 1 ]; then 
				error_c "Missing  build architetture Phase $2" "project : $1"
			fi		
			CROSS=$(xml_value $1 "/egg/project/build/step[@id='$2']/cross")
			equs "$CROSS"  
			if [ $? -eq 1 ]; then 
				error_c "Missing  build cross platform Phase $2" "project : $1"
			fi	
			INDEX="$PRI%$NAME%$ARCH%$CROSS:$1"
			BSEQ[$INDEX]="$INDEX"	
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}

#$1 projects
#$2 source dir
function call_autoconf(){
local PWD=$(pwd)
cd $2
dolog "action call autoconf :  - project $1"
autoconf
if [ $? -ne 0 ]; then
	error_c " Autoconf fail " "  - project $1"
fi
cd $PWD
}

#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
function add_pre_conf(){
declare -i i=0
local VALUE=""
local MODE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action pre_conf"	
		xml_count $1 "/egg/project/build/step[@id='$2']"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id='$2']/pre_conf"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id='$2']/pre_conf[@id='$i']/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre conf id=$i value Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id='$2']/pre_conf[@id='$i']/mode")	
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre conf id=$i mode Phase $2" "project : $1"
				fi
				MODE=$(echo $MODE  | tr '[:lower:]' '[:upper:]')
				case $MODE in 
					SCRIPTS)
						rsync -sy "$REPO/$1/$VALUE" "$4/$VALUE"				
						echo "$4/$VALUE  $1 $2 $5 $4 $REPO/$1 $SOURCES/$1 $IMAGES/$5"  >> $3
					;;		
					SOURCE)
						rsync -sy "$REPO/$1/$VALUE" "$4/$VALUE"				
						echo "source $4/$VALUE  $1 $2 $5 $4 $REPO/$1 $SOURCES/$1 $IMAGES/$5"  >> $3
					;;		
					CODE)
						echo "$VALUE"  >> $3
					;;		
					*)
					error_c "Unknow  pre conf id=$i mode Phase $2" "project : $1"
					;;
				esac				
				i=$((i+1))
				done 
			else
				echo "# no pre configure script available for prject : $1" >> $3
			fi
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
echo " "  >> $3
}


#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
function add_post_conf(){
declare -i i=0
local VALUE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action post_conf"	
		xml_count $1 "/egg/project/build/step[@id='$2']"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id='$2']/post_conf"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id='$2']/post_conf[@id='$i']/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post conf id=$i Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id='$2']/pre_conf[@id='$i']/mode")	
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre conf id=$i mode Phase $2" "project : $1"
				fi
				MODE=$(echo $MODE  | tr '[:lower:]' '[:upper:]')
				case $MODE in 
					SCRIPTS)
						rsync -sy "$REPO/$1/$VALUE" "$4/$VALUE"				
						echo "$4/$VALUE  $1 $2 $5 $4 $REPO/$1 $SOURCES/$1 $IMAGES/$5"  >> $3
					;;		
					SOURCE)
						rsync -sy "$REPO/$1/$VALUE" "$4/$VALUE"				
						echo "source $4/$VALUE  $1 $2 $5 $4 $REPO/$1 $SOURCES/$1 $IMAGES/$5"  >> $3
					;;		
					CODE)
						echo "$VALUE"  >> $3
					;;		
					*)
					error_c "Unknow  post conf id=$i mode Phase $2" "project : $1"
					;;
				esac				
				i=$((i+1))
				done 
			else
				echo "# no post configure script available for prject : $1" >> $3
			fi
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
echo " "  >> $3
}

#$1 project
#$2 step id
#$3 file out
function add_extra_conf(){
declare -i i=0
local VALUE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action extra_conf"	
		xml_count $1 "/egg/project/build/step[@id='$2']"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id='$2']/extra_conf"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id='$2']/extra_conf[@id='$i']")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  extra conf id=$i Phase $2" "project : $1"
				fi
				echo "\\"  >> $3
				echo -n	"$VALUE "  >> $3
				i=$((i+1))
				done 
			fi
		fi
		echo " > /dev/null" >>  $3
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
echo " "  >> $3
}



#$1 id 0,1,2,3
#$2 composite name priority%name%arch%cross:project

function configure_packet(){
#retrieve data...
local PRIORITY=""
local BUILD_NAME=""
local BUILD_ARCH=""
local BUILD_CROSS=""
local BUILD_PROJECT=""
local AA=$(echo $2 | sed -e 's/%/   /g' | sed -e 's/:/   /g' )
PRIORITY=$(echo $AA | awk '{print $1}')
BUILD_NAME=$(echo $AA | awk '{print $2}')
BUILD_ARCH=$(echo $AA | awk '{print $3}')
BUILD_CROSS=$(echo $AA | awk '{print $4}')
BUILD_PROJECT=$(echo $AA | awk '{print $5}')
 
local CONF_RUN="$BUILD/$BUILD_PROJECT/$BUILD_NAME/$BUILD_NAME""_bootstrap.sh"
local DEST="$IMAGES/$BUILD_NAME"
mkdir -p $BUILD/$BUILD_PROJECT
mkdir -p $BUILD/$BUILD_PROJECT/$BUILD_NAME
rm -rf $BUILD/$BUILD_PROJECT/$BUILD_NAME/*
mkdir -p $DEST
rm -rf $DEST/*
touch $CONF_RUN
chmod +x $CONF_RUN
prepare_script $1 "START CONFIGURE" $CONF_RUN
add_pre_conf "$BUILD_PROJECT" "$1" "$CONF_RUN" "$BUILD/$BUILD_PROJECT/$BUILD_NAME"  "$BUILD_NAME"
if [ -e $SOURCES/$BUILD_PROJECT/configure ]; then
	echo -n "$SOURCES/$BUILD_PROJECT/configure --prefix=$DEST --target=$BUILD_CROSS ">> $CONF_RUN
else
	if [ -e $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure ]; then
		AA=$(ls $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure)
		echo -n "$AA --prefix=$DEST --target=$BUILD_CROSS ">> $CONF_RUN
	else
		if [ -e $SOURCES/$BUILD_PROJECT/configure.ac ]; then
			call_autoconf $BUILD_PROJECT $SOURCES/$BUILD_PROJECT
			echo -n "$SOURCES/$BUILD_PROJECT/configure --prefix=$DEST --target=$BUILD_CROSS ">> $CONF_RUN
		else
			if [ -e $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure.ac ]; then
				call_autoconf $BUILD_PROJECT $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*
				AA=$(ls $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure)
				echo -n "$AA --prefix=$DEST --target=$BUILD_CROSS">> $CONF_RUN
			else
			error_c "Cannot locate configure script" "  - project $BUILD_PROJECT"
			fi
		fi
	fi
fi	
add_extra_conf "$BUILD_PROJECT" "$1" "$CONF_RUN" "$BUILD/$BUILD_PROJECT/$BUILD_NAME"  "$BUILD_NAME"
add_post_conf "$BUILD_PROJECT" "$1" "$CONF_RUN" "$BUILD/$BUILD_PROJECT/$BUILD_NAME"  "$BUILD_NAME"
end_script $1 "END CONFIGURE" $CONF_RUN
}


#$1 build id number
function configure_all_packet(){
local i=""
for i in $ALL_PACKETS; do
	insert_packet $i $1 
done
SORTREQ=$(echo ${BSEQ[*]}| tr " " "\n" | sort -n )
for i in $SORTREQ; do
	configure_packet  $1 $i
done
}



function usage(){
	print_c "$BLUE_LIGHT" "usage : ./configure.sh <opt> <phase> <args>"
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-D or --debug : set debug mode" 
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "phase = 0,1,2..." 
	print_c  "$PURPLE" "ARGS" "$GREEN" "args for options"
	exit 1
}

#$1 build id number
function main(){
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
		*)
		usage
		error_c "Command line" " unknow option $i"
		;;
	esac
	done
fi

if [ "$ARGV" != "" ]; then
	for i in $ARGV; do
	print_c "$GREEN_LIGHT" "argv " "$YELLOW"  "$i"
	done
fi
#set log to download
LOGFILE="$LOGFILE""-configure.txt"
touch "$LOGFILE"
#sort project in repo to bin search
for key in $ALL_PACKETS; do MAP[$key]="$key"; done  
# sync repo file to build path 
dolog "Force resync work repo"
rsync -ry $OREPO $REPO
if [ $? -ne 0 ]; then
	error_c "Cannot  sync work repository"
fi
configure_all_packet  "$ARGV"
}


#$1 step id build number ex : ./configire.sh 0 -> configure build step id==0

main "$@"