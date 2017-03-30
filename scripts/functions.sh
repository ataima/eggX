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



#$1.... string to log
function dolog(){
	if [ -f "$LOGFILE" ] && [ "$1" != "" ]; then 
			echo "$1" "$2" "$3" "$4" >> "$LOGFILE"
	fi
}


#$1 color
#$2   string
function print_c(){
echo -e $(echo $1) "$2" $(echo $3) "$4"$(echo $5) "$6" $(echo $REPLACE)
dolog "$2" "$4" "$6"
}



#$1   string
#$2   string
#$3   string
function error_c(){
print_c "$WHITE" "--------------------------------------------------"
print_c "$RED_LIGHT" "ERROR : " "$BLUE_LIGHT" " - $1" 
print_c "$YELLOW" "   -  $2" "$BLUE_LIGHT" "$3"
print_c "$WHITE" "--------------------------------------------------"
exit 1
}



#$1   string
#$2   string
#$3   string
function warning_c(){
print_c "$WHITE" "--------------------------------------------------"
print_c "$RED_LIGHT" "WARNING : " "$BLUE_LIGHT" " - $1" 
print_c "$GREEN_LIGHT" "   -  $2" "$BLUE_LIGHT" "$3"
print_c "$WHITE" "--------------------------------------------------"
}


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
	if [ ${i:0:1} == "-" ]; then
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
 echo $VALUE
 else
	echo "Conf.egg referred to project $PRJ"
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