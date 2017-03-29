#!/bin/sh 

# include configuration
source "$SCRIPT_DIR/conf.sh"
# include io functions
source "$SCRIPT_DIR/functions.sh"


SCRIPT_DIR=$OROOT/scripts
OREPO=$OROOT/repo/.

declare -A MAP    

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
function configure_packet(){
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action CONFIGURE"		
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


function configure_all_packet(){
local i=""
for i in $ALL_PACKET; do
	configure_packet $i
done
}


function main(){
#set log to download
LOGFILE="$LOGFILE""-configure.txt"
touch "$LOGFILE"
#sort project in repo to bin search
for key in $ALL_PACKETS; do MAP[$key]="$key"; done  
configure_all_packet
}

main "$@"