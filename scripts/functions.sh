#!/bin/sh 

#Colors
WHITE=" -e \E[1;37m"
GRAY_LIGHT=" -e \E[0;37m"
GRAY_DARK=" -e \E[1;30m"
BLUE=" -e \E[0;34m"
BLUE_LIGHT=" -e \E[1;34m"
GREEN=" -e \E[0;32m"
GREEN_LIGHT=" -e \E[1;32m"
CYAN=" -e \E[0;36m"
CYAN_LIGHT=" -e \E[1;36m"
RED=" -e \E[0;31m"
RED_LIGHT=" -e \E[1;31m"
PURPLE=" -e \E[0;35m"
PURPLE_LIGHT=" -e \E[1;35m"
BROWN=" -e \E[0;33m"
YELLOW=" -e \E[1;33m"
BLACK=" -e \E[0;30m"
REPLACE=" -e \E[0m"




#PUBLIC FUNCTION EXPORTED TO ALL GENERATED SCRIPTS 
#$1 color
#$2   string
function print_c(){
echo -e $(echo $1) "$2" $(echo $3) "$4"$(echo $5) "$6" $(echo $REPLACE)
}


# $1..3 argv
function print_s_ita(){
local A1=$(printf "%-20s" "$1")
local A2=$(printf "%-20s" "$2")
local A3=$(printf "%-20s" "$3")
echo  $(echo $GREEN_LIGHT) "$A1" $(echo $WHITE) "$A2" $(echo $RED_LIGHT) "$A3" $(echo $REPLACE)
}




#none
function print_del_ita() {
print_s_ita "--------------------" "--------------------" "--------------------"
}
# $1..3 argv
function print_ita(){
print_del_ita
print_s_ita "$1" "$2" "$3"
}

#$1   string
#$2   string
#$3   string
function error_c(){
print_del_ita
print_c "$RED_LIGHT" "ERROR : " "$BLUE_LIGHT" " - $1" 
if [ "$2" ]; then
	print_c "$WHITE" "	 >" "$YELLOW" " - $2" 
	if [ "$3" ]; then
		print_c "$WHITE" "	 >" "$YELLOW" " - $3" 
		if [ "$4" ]; then
			print_c "$WHITE" "	 >" "$YELLOW" " - $4" 
		fi
	fi
fi
print_c "$YELLOW" "PATH :" $(pwd)
print_c "$YELLOW" "FILE :" "$0"
print_c "$YELLOW" "LINE :" "${BASH_LINENO[0]}"
print_del_ita
exit 1
}



#$1   string
#$2   string
#$3   string
function warning_c(){
print_del_ita
print_c "$GREEN_LIGHT" "WARNING : " "$BLUE_LIGHT" "- $1" 
if [ "$2" ]; then
	print_c "$WHITE" "	 >"  "$YELLOW" " - $2" 
	if [ "$3" ]; then
		print_c "$WHITE" "	 >"  "$YELLOW" " - $3" 
		if [ "$4" ]; then
			print_c "$WHITE" "	 >"  "$YELLOW" " - $4" 
		fi
	fi
fi
print_del_ita
}

#$1   s...S10
function info_simple(){
print_del_ita
print_c "$WHITE" "$@" 
print_del_ita
}

#$1   string
#$2   string
#$3   string
#$4   string
#$5   string
#$6   string
#$7   string
#$8   string
function help_c(){
print_del_ita
print_c "$GREEN_LIGHT" "HELP :" "$BLUE_LIGHT" "$1"
if [ "$2" ]; then
        print_c "$WHITE" "     >"  "$YELLOW" "$2"
        if [ "$3" ]; then
                print_c "$WHITE" "     >"  "$YELLOW" "$3"
                if [ "$4" ]; then
                        print_c "$WHITE" "     >"  "$YELLOW" "$4"
                        if [ "$5" ]; then
                                print_c "$WHITE" "     >"  "$YELLOW" "$5"
                                if [ "$6" ]; then
                                        print_c "$WHITE" "     >"  "$YELLOW" "$6"
                                        if [ "$7" ]; then
						print_c "$WHITE" "     >"  "$YELLOW" "$7"
						if [ "$8" ]; then
							print_c "$WHITE" "     >"  "$YELLOW" "$8"
						fi
                                        fi
                                fi
                        fi
                fi
        fi
fi
print_del_ita
}


#$1 full filename
function check_exist(){
if  [ -e "$1" ] && [ -f "$1" ] ; then 
	return 0
fi
return 1
}
############################## FUNCTION TO USE IN conf.egg to CHECK ....
#$1 file to execute 
#$2 string to compare
function check_version(){
if [ $# -ne 2 ]; then 
	error_c "Missing parameter on call check_version" "$1 $(basename "$0")"
fi
local VV=$(which $1)
if [ ! "$VV" ]; then
	error_c "which $1 fail, PATH : $PATH" "$1 $(basename "$0")"
fi
local VERSION=`$1 --version `
if [ $? -ne 0 ]; then 
	error_c "Request $1 --version Fail!" "$1 $(basename "$0")"
fi
if [ ! "$(echo $VERSION | grep $2)" ]; then
	error_c "Request $1 : $2 !=$VERSION" "$1 $(basename "$0")"
fi
return 0
}


#$1 projects name  
#$2 step phase
#$3 build value 0 to configure 1 to build 2 is stable ( configured + builded +installed )
function check_build_status(){
local RES=0
if [ $# -ne 3 ]; then 
	error_c "Missing parameter on call checck_build_status" "$1_$2 $(basename "$0")"
fi
check_exist "$BUILDS/$1_$2/status"
if [ $? -eq 1 ]; then
	error_c "File $BUILDS/$1_$2/status not exist!" "$1_$2 $(basename "$0")"
fi
local ST=$(cat $BUILDS/$1_$2/status)
if [ $ST -ne $3 ]; then
	error_c "Request $1_$2 Status : $3 != $ST " "$1_$2 $(basename "$0")"
fi
return 0
}


#$1 projects name  
#$2 step phase
function check_depend(){
check_build_status $1 $2 2
}

#$1 file name
function check_file_exist(){
if [ $# -ne 1 ]; then 
	error_c "Missing parameter on call build_status" " $(basename "$0")"
fi
check_exist $1
if [ $? -ne 0 ]; then 
	error_c "File $1 not exist!" " $(basename "$0")"
fi
return 0
}



#COPYTODEFAULTSCRIPT DO NOT REMOVE MARK TO COPY FUNCTION.Sh IN default_script

#PRIVATE FUNCTION 

# $1  string 
# $2  string
function equs(){
local RES=0
if [ "$1" == "$2" ]; then
	RES=1
fi
return $RES
}

# $1  string 
# $2  string
function noequs(){
local RES=0
if [ "$1" != "$2" ]; then
	RES=1
fi
return $RES
}


# $1  string 
# $2  array string
function range_multi(){
local RES=0
local AA=$(echo $2 | grep $1)
if [ "AA" != "" ]; then
	RES=1
fi
return $RES
}

#global variable for input arg
# collection of input option all string with -xx
OPT_ARGV=""
#all argv not in -
ARGV=""
#number of input in ARGV
ARGN=0
# called with "$@"
function input_arg(){
OPT_ARGV=""
ARGV=""
ARGN=0
local i=""
for i in "$@" ; do
	if [ "${i:0:1}" == "-" ]; then
		OPT_ARGV+=" $i"
	else
		ARGV+=" $i"
		ARGN=$((ARGN+1))
	fi
done
}

#$1 project
#$2 xml node 
#return value
function xml_value(){
 local PRJ=$(xmlstarlet sel -t  -v '/egg/project/name' -n $REPO/$1/conf.egg)
 if [ "$PRJ" == "$1" ];then	
	 local VALUE=$(xmlstarlet sel -t  -v "$2" -n $REPO/$1/conf.egg)
	 
	 #if [  "${VALUE:0:1}" == "$" ]; then 
		 #if a env variable
	#	 local UV=$(echo $VALUE | sed -e 's/\$//g')
	#	 VALUE=$(env | grep $UV | sed -e 's/=/ /g' | awk '{print $2}')
	 #fi
	 echo $VALUE
 else
	error_c "Mistake in project name" "Conf.egg referred to $PRJ : $1"
 fi
}


#$1 project
#$2 xml node
#return num node match
function xml_count(){
declare -i RES=0
local PRJ=$(xmlstarlet sel -t  -v '/egg/project/name' -n $REPO/$1/conf.egg)
 if [ "$PRJ" == "$1" ];then	
RES=$(xmlstarlet sel -t  -v "count($2)" -n $REPO/$1/conf.egg)
fi
return $RES
}

#$1 file 
#$2 xml node
#return num node match
function xml_multi_repo_count(){
declare -i RES=0
RES=$(xmlstarlet sel -t  -v "count($2)" -n $1)
return $RES
}

#$1 file 
#$2 xml node
#return num node match
function xml_multi_repo_value(){
local VALUE=""
VALUE=$(xmlstarlet sel -t  -v "$2" -n $1)
echo $VALUE
}

#$1 project
#$2 xml node
#return num node match
function xml_get_env(){
HW_ARCH=$(arch)
local MAINFILE="$REPO/conf.egg"
declare -A XNAME="root  repo sources images store repobackup build editor \
				 start_path"
local II=""
for II in $XNAME; do
	local VALUE=$(xmlstarlet sel -t  -v "egg/conf/$II" -n $MAINFILE)
	if [ "$VALUE" ]; then
		eval $(echo $II |   tr '[:lower:]' '[:upper:]')="$VALUE"
	fi	
done
}


#$1 param to test
function isNumber(){
local RES='^[0-9]+$'
if ! [[ $1 =~ $RES ]] ; then
   return 1
fi
}

#$1 fulle filename
function getFileSize(){
if  [ -e "$1" ] && [ -f "$1" ] 
then 
	echo   -n $(wc -c < "$1")
	return 1
fi
echo -n 0
return 0
}