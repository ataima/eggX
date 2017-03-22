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
