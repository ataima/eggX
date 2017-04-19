#!/bin/sh 

if [ "$OROOT" == "" ] ; then
	OROOT="$HOME/eggX"
fi

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
#initial value PATH
START_PATH="/usr/bin:/sbin:/bin"
MYPATH=""
CPATH=""
C_INCLUDE_PATH=""
CPLUS_INCLUDE_PATH=""


# include io functions
source "$SCRIPT_DIR/functions.sh"



declare -A MAP    

declare -A BSEQ    
declare -A SORTREQ

ALL_PACKETS=$(ls $OROOT/repo  | sed 's/conf.egg//g')

# test if exist project <name> from packets list...
# $1 packet name
function check_project(){
local tmp=""
if [[ -n "${MAP[$1]}" ]]; then
	return 1
fi
return 0
}


#$1 build name
#$2 dir
function remove_path(){
local V=$(echo $MYPATH | sed -e 's/:/  /g')
local OLD=$2
MYPATH=""
for I in $V; do
	if [ "$I" != "$OLD" ]; then
		MYPATH="$MYPATH:$I" 
	fi
done
}


#$1 build name
#$2 dir
function add_path(){
local NEW=$2
local V=$(echo $MYPATH | sed -e 's/:/  /g')
for I in $V; do
	if [ "$I" == "$NEW" ]; then
		return 
	fi
done
MYPATH="$NEW:"$MYPATH
}

#$1 build name
#$2 dir
function set_path(){
MYPATH="$2"
}

#$1 project
#$2 build phase number 0,1,2.....
function insert_packet(){
local PRI=""
local NAME=""
local ARCH=""
local CROSS=""
local SILENT=""
local INDEX=""
local NUM=0
local TPATH=""
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
				#optional				
				INDEX="$PRI%$1%$NAME"
				#echo "-->$INDEX"
				BSEQ[$INDEX]="$INDEX"	
			else
				warning_c " no build step $2  !" "project : $1"
			fi
		else
			warning_c " no build  !" "project : $1"
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}



#$1 project
#$2 build phase number 0,1,2.....
function manage_path_pre(){
local TPATH=""
local NUM=0
local MAX=0
local ID=0
local NAME=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action PATH manage"	
		xml_count $1 "/egg/project/build"
		NUM=$?
		if [ $NUM -eq 1 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
			NUM=$?
			if [ $NUM -ne 0 ]; then	
				NAME=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/name")	
				equs "$NAME"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  build name Phase $2 manage path pre" "project : $1"
				fi 			
				xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path/pre"
				NUM=$?
				if [ $NUM -ne 0 ]; then 	
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path/pre/remove"
					NUM=$?
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path/pre/add"
					MAX=$?
					if [ $NUM -gt $MAX ]; then
						MAX=$NUM
					fi										
					ID=0
					while [ $ID -lt $MAX ]; do
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path/pre/remove[@id=\"$ID\"]")
						if [ "$TPATH" != "" ]; then
							remove_path $NAME $TPATH
						fi
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path/pre/add[@id=\"$ID\"]")
						if [ "$TPATH" != "" ]; then
							add_path $NAME $TPATH
						fi
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path/pre/set")
						if [ "$TPATH" != "" ]; then
							set_path $NAME $TPATH
							break
						fi
						ID=$((ID+1))
					done 
				fi				
			fi	
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}





#$1 project
#$2 build phase number 0,1,2.....
function manage_path_post(){
local TPATH=""
local NUM=0
local MAX=0
local ID=0
local NAME=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action PATH manage"	
		xml_count $1 "/egg/project/build"
		NUM=$?
		if [ $NUM -eq 1 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
			NUM=$?
			if [ $NUM -ne 0 ]; then	
				NAME=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/name")		
				equs "$NAME"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  build name Phase $2 manage path post" "project : $1"
				fi 						
				xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path/post"
				NUM=$?
				if [ $NUM -ne 0 ]; then 	
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path/post/remove"
					NUM=$?
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path/post/add"
					MAX=$?
					if [ $NUM -gt $MAX ]; then
						MAX=$NUM
					fi					
					ID=0
					while [ $ID -lt $MAX ]; do
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path/post/remove[@id=\"$ID\"]")
						if [  "$TPATH"  !=  ""  ]; then
							remove_path $NAME $TPATH
						fi
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path/post/add[@id=\"$ID\"]")
						if [  "$TPATH"  !=  ""  ]; then
							add_path $NAME $TPATH
						fi
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path/post/set")
						if [ "$TPATH" != "" ]; then
							set_path $NAME $TPATH
							break
						fi
						ID=$((ID+1))
					done 
				fi					
			fi	
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
}


#$1 project
#$2 step id
#$3 fileout
#$4 build name
#$5 arch
#$6 cross
#$7 deploy
#$8 prefix
function generate_setenv(){
	local SRC=""
	if [ -e $SOURCES/$1/$1-*/configure ]; then
		SRC=$(ls -d $SOURCES/$1/$1-*)
	else
		if [ -e $SOURCES/$1/configure.ac ]; then
			SRC=$SOURCES/$1
		else
			if [ -e $SOURCES/$1/$1-*/configure.ac ]; then
				SRC=$(ls -d $SOURCES/$1/$1-*)
			else
				SRC=$SOURCES/$1
			fi
		fi
	fi
	echo "#!/bin/sh" > "$3"
	echo "#unset all except $HOME ..." >> "$3"
	ENV=$(env | sed 's/=.*//' | tr '\n' ' ' | sed -e 's/HOME//g')
	echo "ENV=\"$ENV\"" >> "$3"		
	echo "for i in \$ENV ; do ">> "$3"
	echo " unset \$i" >> "$3"
	echo "done" >> "$3"
	echo "#done unset all" >> "$3"
	echo "export PROJECT=$1" >> "$3"
	echo "export SOURCES=$SOURCES" >> "$3"
	echo "export BUILDS=$BUILD/$4">> "$3"
	echo "export SOURCE=$SRC" >> "$3"
	echo "export BUILD=$BUILD/$4/$1/build" >> "$3"
	echo "export DEPLOYS=$IMAGES/$4" >> "$3"
	echo "export DEPLOY=$7" >> "$3"
	echo "export ARCH=$5">> "$3"
	echo "export CROSS=$6">> "$3"
	echo "export CFLAGS=$CFLAGS" >> "$3"
	echo "export CPPFLAGS=$CPPFLAGS" >> "$3"
	echo "export CXXFLAGS=$CXXFLAGS" >> "$3"
	echo "export LDFLAGS=$LDFLAGS" >> "$3"
	echo "export LIBS=$LIBS" >> "$3"
	echo "export CPATH=$CPATH" >> "$3"
	echo "export C_INCLUDE_PATH=$C_INCLUDE_PATH" >> "$3"
	echo "export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH" >> "$3"	
	echo "export PATH=$MYPATH" >> "$3"	
	echo "export NATIVE=$(/usr/bin/gcc -dumpmachine)" >> "$3"
}

#$1 projects
#$2 Step
#$3 title to echo...
#$4 file to write 
#$5 BUILD NAME
#$6 ARCH
#$7 CROSS
function prepare_script_generic(){
local LINE=$(sed -n '/COPYTODEFAULTSCRIPT/{=;p}' $SCRIPT_DIR/functions.sh | sed -e 's/ /\n/g' | head -n 1)
LINE=$((LINE-1))
head $SCRIPT_DIR/functions.sh -n $LINE >> "$4"
echo "source $BUILD/$5/$1/setenv.sh">> "$4"
echo "PWD=\$(pwd)">> "$4"
echo "cd \$BUILD" >> "$4"
echo "" >> "$4"
echo "" >> "$4"
}





#$1 projects
#$2 Step
#$3 title to echo...
#$4 file to write 
function end_script_generic(){
echo "" >> $4
echo "" >> $4
echo "cd \$PWD" >> "$4"
echo "" >> $4
echo "" >> $4
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
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/configure/pre"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/configure/pre[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre conf id=$i value Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/configure/pre[@id=\"$i\"]/mode")	
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
						echo "if [ $? -ne 0 ]; then">> $3
						echo " error_c \"Custom command  Fail!\" \"$VALUE\"" >> $3
						echo "fi" >> $3
					;;		
					*)
					error_c "Unknow  pre build id=$i mode Phase $2" "project : $1"
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
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/configure/post"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/configure/post[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post conf id=$i Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/configure/post[@id=\"$i\"]/mode")	
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post conf id=$i mode Phase $2" "project : $1"
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
						echo "if [ $? -ne 0 ]; then">> $3
						echo " error_c \"Custom command  Fail!\" \"$VALUE\"" >> $3
						echo "fi" >> $3
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
#$4 silent
#$5 prefix 
#$6 target
function add_extra_conf(){
declare -i i=0
local VALUE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action extra_conf"	
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/configure/extra"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/configure/extra[@id=\"$i\"]")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  extra conf id=$i Phase $2" "project : $1"
				fi
				echo 	"$VALUE \\"  >> $3
				i=$((i+1))
				done 
			fi
		fi
		echo 	"$5 \\"  >> $3
		if  [ "$4" == "yes" ]; then 
			echo " $6 > /dev/null" >>  $3
		else
			echo 	"$6 "  >> $3		
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
echo " "  >> $3
echo "RES=\$?" >> $3
echo "if [ \$RES -ne 0 ]; then" >> $3
echo "    error_c \"Configure return error: \$RES \" \"  - project : \$PROJECT step \$STEP\"" >> $3
echo "fi" >> $3 
}

#$1 project
#$2 step id
#$3 path build
#$4 build name
#$5 arch
#$6 cross
#$7 silent
#$8 thread //max 
#$9 deploy
#$10 prefix
#<make>
#<rule id=0>
#<name>all</name> 
#<pre id=0></pre>    optional
#<post id=0></post> optional
#<tread></thread>    optional
#</rule>
#</make>
#
function generate_build_rules(){
#build
declare -i i=0
local NAME
local TREAD
declare -i NUM_R=0
local SH_BUILD="$3/build.sh"
rm -f "$SH_BUILD" 
touch "$SH_BUILD"
chmod +rwx "$SH_BUILD"
prepare_script_generic "$1" "$2" "Start build " "$SH_BUILD" "$4" "$5" "$6"
echo "declare -i start_time">> "$SH_BUILD"
echo "declare -i stop_time">> "$SH_BUILD"
echo "declare -i total_time">> "$SH_BUILD"
#------------------------------------------------------------------------------------------------------------------
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action generate build rules"	
		#set -x ; trap read debug
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM_R=$?
		if [ $NUM_R -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/make/rule"
			NUM_R=$?
			if [ $NUM_R -ne 0 ]; then
				while  [  $i -lt $NUM_R  ];  do
					NAME=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$i\"]/name")	
					equs "$NAME $i"  
					if [ $? -eq 1 ]; then 
						error_c "Missing  make rule name id=$i Phase $2" "project : $1"
					fi

					THREAD=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$i\"]/thread")
					equs "$THREAD"  
					if [ $? -eq 0 ]; then 
						if  [  $THREAD -gt $8 ] ; then 
							THREAD="$8"
						fi
					else
						THREAD="$8"	
					fi						
					add_pre_build "$1" "$2" "$SH_BUILD" "$3" "$4" "$i"
					add_entry_in_main_build_script "$1" "$3"  "$SH_BUILD" "$7" "$THREAD" "$8" "$NAME"
					add_post_build "$1" "$2" "$SH_BUILD" "$3" "$4" "$i"
					i=$((i+1))
				done 
			fi
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
#------------------------------------------------------------------------------------------------------------------
end_script_generic "$1" "$2" "done  build " "$SH_BUILD"
}

#$1 project
#$2 step id
#$3 path build
#$4 build name
#$5 arch
#$6 cross
#$7 silent
#$8 thread
#$9 deploy

function generate_clean_rule(){
local SH_CLEAN="$3/clean.sh"
rm -f "$SH_CLEAN" 
touch "$SH_CLEAN" 
chmod +rwx "$SH_CLEAN" 
# clean 
prepare_script_generic "$1" "$2" "Start clean build " "$SH_CLEAN" "$4" "$5" "$6"
echo "if [ -f \$BUILD/Makefile ]; then " >> "$SH_CLEAN"
if [ "$7" == "yes" ]; then 
	echo "	make --silent -C \$BUILD clean > /dev/null 2>&1 " >> "$SH_CLEAN"
else
	echo "	make -C \$BUILD  clean ">> "$SH_CLEAN"
fi
echo "	if [ \$? -ne 0 ]; then">> "$SH_CLEAN"
echo "    	error_c \"Error on clean \" \"  - project \$1\"" >>"$SH_CLEAN"
echo "	fi"  >> "$SH_CLEAN"
echo "fi" >> "$SH_CLEAN"
echo "" >> "$SH_CLEAN"
echo "" >> "$SH_CLEAN"
end_script_generic "$1" "$2" "done clean build " "$SH_CLEAN"
}

#$1 project
#$2 step id
#$3 path build
#$4 build name
#$5 arch
#$6 cross
#$7 silent
#$8 thread
#$9 deploy

function generate_distclean_rule(){
local SH_DISTCLEAN="$3/distclean.sh"
rm -f "$SH_DISTCLEAN"  
touch "$SH_DISTCLEAN" 
chmod +rwx "$SH_DISTCLEAN" 
#distclean 
prepare_script_generic "$1" "$2" "Start distclean build " "$SH_DISTCLEAN" "$4" "$5" "$6"
echo "cd \$PWD " >> "$SH_DISTCLEAN"
echo "rm -rf \$BUILD " >> "$SH_DISTCLEAN"
echo "" >> "$SH_DISTCLEAN"
echo "" >> "$SH_DISTCLEAN"
end_script_generic "$1" "$2" "done distclean build " "$SH_DISTCLEAN"
}



#$1 project
#$2 step id
#$3 path build
#$4 build name
#$5 arch
#$6 cross
#$7 silent
#$8 thread
#$9 deploy
function generate_rebuild_rule(){
local SH_REBUILD="$3/rebuild.sh"
rm -f  "$SH_REBUILD" 
touch "$SH_REBUILD"
chmod +rwx "$SH_REBUILD"
#rebuild
prepare_script_generic "$1" "$2" "Start Rebuild " "$SH_REBUILD" "$4" "$5" "$6"
echo "cd .." >> "$SH_REBUILD"
echo "$SH_CLEAN" >> "$SH_REBUILD"
echo "$SH_DISTCLEAN" >> "$SH_REBUILD"
echo "$3/bootstrap.sh" >> "$SH_REBUILD"
echo "$SH_BUILD" >> "$SH_REBUILD"
end_script_generic "$1" "$2" "done  rebuild " "$SH_REBUILD"
}
#$1 project
#$2 step id
#$3 path build
#$4 build name
#$5 arch
#$6 cross
#$7 silent
#$8 thread
#$9 deploy
function add_build_script(){
local PREFIX=$(basename "$9")
generate_setenv "$1" "$2" "$3/setenv.sh" "$4" "$5" "$6" "$9" "$PREFIX"
generate_clean_rule $@
generate_distclean_rule $@ 
generate_build_rules $@
generate_rebuild_rule $@
}

#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
#$6 rule index
function add_pre_build(){
declare -i i=0
local VALUE=""
local MODE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action pre_build"	
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$6\"]/pre"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$6\"]/pre[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre build id=$i value Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$6\"]/pre[@id=\"$i\"]/mode")	
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre build id=$i mode Phase $2" "project : $1"
				fi
				MODE=$(echo $MODE  | tr '[:lower:]' '[:upper:]')
				case $MODE in 
					SCRIPTS)
						rsync -sy "$REPO/$1/$VALUE" "$4/$VALUE"				
						echo "$4/$VALUE  $1 $2 $5 $4 $REPO/$1 $SOURCES/$1 $IMAGES/$5"  >> "$3"
					;;		
					SOURCE)
						rsync -sy "$REPO/$1/$VALUE" "$4/$VALUE"				
						echo "source $4/$VALUE  $1 $2 $5 $4 $REPO/$1 $SOURCES/$1 $IMAGES/$5"  >> "$3"
					;;		
					CODE)
						echo "$VALUE"  >> "$3"
						echo "if [ $? -ne 0 ]; then">> $3
						echo " error_c \"Custom command  Fail!\" \"$VALUE\"" >> $3
						echo "fi" >> $3						
					;;		
					*)
					error_c "Unknow  pre build id=$i mode Phase $2" "project : $1"
					;;
				esac				
				i=$((i+1))
				done 
			else
				echo "# no pre build script available for prject : $1" >> "$3"
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
#$6 rule index
function add_post_build(){
declare -i i=0
local VALUE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action post_build"	
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$6\"]/post"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$6\"]/post[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post build id=$i Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/make/rule[@id=\"$6\"]/post[@id=\"$i\"]/mode")	
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post build id=$i mode Phase $2" "project : $1"
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
						echo "if [ $? -ne 0 ]; then">> $3
						echo " error_c \"Custom command  Fail!\" \"$VALUE\"" >> $3
						echo "fi" >> $3
					;;		
					*)
					error_c "Unknow  post build id=$i mode Phase $2" "project : $1"
					;;
				esac				
				i=$((i+1))
				done 
			else
				echo "# no post build script available for prject : $1" >> $3
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
#$2 build path
#$3 file out
#$4 silent 
#$5 threads
#$6 max thread
#$7 make rule name
function add_entry_in_main_build_script(){
echo "start_time=\$(date +%s)">> "$3"
echo " print_s_ita \"       Make \"  \"$7-$6:$5\"  \"start\"" >> "$3"
if [ "$4" == "yes" ]; then 
	echo "make --silent -C \$BUILD -j$5 $7 > /dev/null 2>&1 " >> "$3"
else
	echo "make -C \$BUILD  -j$5 $7 ">> "$3"
fi
echo "if [ \$? -ne 0 ]; then">> "$3"
echo "    error_c \"Error on build \" \"  - project \$1\"" >>"$3"
echo "fi"  >> "$3"
echo "stop_time=\$(date +%s)">> "$3" 
echo "total_time=\$((stop_time-start_time))">> "$3" 
echo "print_s_ita \"       ... \"  \"done\"  \"\$total_time sec\" ">> "$3" 
}


#$1 project
#$2 build phase number 0,1,2.....
function create_configure_cmd(){
local PRI=""
local NAME=""
local ARCH=""
local CROSS=""
local SILENT=""
local INDEX=""
local PREFIX=""
local BTARGET=""
local BDEST=""
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
				ARCH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/arch")		
				equs "$ARCH"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  build architetture Phase $2" "project : $1"
				fi		
				CROSS=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/cross")
				equs "$CROSS"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  build cross platform Phase $2" "project : $1"
				fi	
				SILENT=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/silent")
				#optional
				if [ $SILENT ]; then
					range_multi "$SILENT" "yes no"
					if [ $? -eq 0 ]; then 
						error_c "silent value error $SILENT-yes or no only! Phase $2" "project : $1"
					fi
				else
				#default
				SILENT="yes"
				fi
				THREADS=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/threads")
				#optional
				if [ $THREADS ]; then
					range_multi "$THREADS" "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16"
					if [ $? -eq 0 ]; then 
						error_c "Threads value error $THREADS-0..16 only! Phase $2" "project : $1"
					fi
				else
					#default
					THREADS=1
				fi
				PREFIX=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/prefix")
				#optional				
			fi	
		fi
	else
		error_c "Missing conf.egg file " "project : $1"
	fi
else
	error_c "Missing project in $REPO " "project : $1"
fi
local C_BUILD="$BUILD/$NAME/$1"
local C_FILE="$C_BUILD/bootstrap.sh"
local DEST="$IMAGES/$NAME/$PREFIX"
rm  -rf "$C_BUILD"
mkdir -p "$C_BUILD"
if [ ! -e "$DEST" ] ; then mkdir -p "$DEST"; fi
touch "$C_FILE"
sync
chmod +x "$C_FILE" 
prepare_script_generic "$1"  "$2" "START CONFIGURE" "$C_FILE" "$NAME" "$ARCH" "$CROSS"
add_pre_conf "$1" "$2" "$C_FILE" "$C_BUILD"  "$NAME"
BTARGET=$(echo $CROSS  | tr '[:lower:]' '[:upper:]')
if [ "$BTARGET" == "NATIVE" ]; then
	BTARGET=""
else
	BTARGET="--target=$CROSS "
fi
BDEST="--prefix=$DEST"
EXTSI=$(echo $SILENT  | tr '[:lower:]' '[:upper:]')
if [ "$EXTSI" != "YES" ]; then
	echo "set -x ">> $C_FILE
fi
if [ -e $SOURCES/$1/configure ]; then
	mkdir -p "$C_BUILD/build"
	echo "$SOURCES/$1/configure \\">> $C_FILE
	add_extra_conf "$1" "$2" "$C_FILE"  "$SILENT" "$BDEST " "$BTARGET"
else
	if [ -e $SOURCES/$1/$1-*/configure ]; then
		mkdir -p "$C_BUILD/build"
		AA=$(ls $SOURCES/$1/$1-*/configure )
		echo "$AA  \\">> $C_FILE
		add_extra_conf "$1" "$2" "$C_FILE"  "$SILENT" "$BDEST " "$BTARGET"
	else
		if [ -e $SOURCES/$1/configure.ac ]; then
			mkdir -p "$C_BUILD/build"
			echo "$SOURCES/$1/configure  \\">> $C_FILE
			add_extra_conf "$1" "$2" "$C_FILE"  "$SILENT" "$BDEST " "$BTARGET"
		else
			if [ -e $SOURCES/$1/$1-*/configure.ac ]; then
				mkdir -p "$C_BUILD/build"
				AA=$(ls $SOURCES/$1/$1-*/configure)
				echo "$AA  \\">> $C_FILE
				add_extra_conf "$1" "$2" "$C_FILE"  "$SILENT" "$BDEST " "$BTARGET"
			else
				if [ -e $SOURCES/$1/Makefile ]; then
					ln -s  "$SOURCES/$1" "$C_BUILD/build"
					echo  "#no configure is needed .... ">> $C_FILE
				else
					if [ -e $SOURCES/$1/$1-*/Makefile ]; then
						AA=$(ls -d $SOURCES/$1/$1-*)
						ln -s  "$AA" "$C_BUILD/build"
						echo  "#no configure is needed .... ">> $C_FILE
					else
						#to add Makefile check
						error_c "Configure script or Makefile missing" "  - project $1"
					fi
				fi
			fi
		fi
	fi
fi	
EXTSI=$(echo $SILENT  | tr '[:lower:]' '[:upper:]')
if [ "$EXTSI" != "YES" ]; then
	echo "set +x ">> $C_FILE
fi
add_post_conf "$1" "$2" "$C_FILE" "$C_BUILD"  "$NAME"
end_script_generic  "$1"  "$2" "END CONFIGURE" "$C_FILE"
#build
add_build_script "$1" "$2"  "$C_BUILD"  "$NAME" "$ARCH" "$CROSS" "$SILENT" "$THREADS" "$DEST" "$PREFIX"
print_ita "STEP : $2:$PRI" "$1"  "configured done !"
}



#$1 project
#$2 build phase number 0,1,2.....
function configure_packet(){
manage_path_pre  $1  $2
create_configure_cmd "$1" "$2"
manage_path_post $1  $2
sync
}


#$1 build phase number 0,1,2.....
function read_default_for_step(){

local VV=""
local VALUE=""
local NAME=""
local NAMES="step_name cflags cppflags cxxflags ldflags libs cpath c_include_path cplus_include_path"
if [ -f $REPO/conf.egg ]; then
	dolog "Read MAIN conf.egg : action set default "
	NUM=$(xmlstarlet sel -t  -v "count(/egg/defaults/step[@id=\"$1\"])" -n $REPO/conf.egg)	
	if [ $NUM -eq 1 ]; then
		for VV in $NAMES; do
			VALUE=$(xmlstarlet sel -t  -v "egg/defaults/step[@id=\"$1\"]/$VV" -n $REPO/conf.egg)
			if [ "$VALUE" ]; then 
				NAME=$(echo $VV |   tr '[:lower:]' '[:upper:]')
				eval "$NAME"="$VALUE"
			fi
		done
	else
		if [ $NUM -eq 0 ]; then
			warning_c "missing defaults conf for step $1"
		else
			error_c "errata conf in main conf.egg" "Step id=$1 duplicate" 
		fi
	fi
else
	error_c "Missing conf.egg file " "on repo"
fi
}


#$@ argv optional
function configure_all_packet(){
local V=""
isNumber $1
if [ $? -ne 0 ]; then
	error_c "first input param must be the step number!" "configure.sh <step x> <optional projets>"
fi

local ID=$1
local PRJS=""
shift

if [ "$#" -eq  0 ]; then
	PRJS=$ALL_PACKETS
else
	PRJS=$@
fi

for V in $PRJS; do
	insert_packet "$V" "$ID" 
done
read_default_for_step "$ID"
SORTREQ=$(echo ${BSEQ[*]}| tr " " "\n" | sort -n )
MYPATH=$START_PATH
for V in $SORTREQ; do
	PRJS=$(echo -n $V | sed 's/%/ /g' | awk '{print $2}')
	if [ "$PRJS" ] ; then 
		configure_packet  "$PRJS" "$ID"
	fi
done
}



function usage(){
	print_c "$BLUE_LIGHT" "usage : ./configure.sh <opt> <phase=always> <args>"
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-D or --debug : set debug mode" 
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "phase = 0,1,2..." 
	print_c  "$PURPLE" "ARGS" "$GREEN" "args for options"
	exit 1
}

#$1 build id number
function main(){
local FORCE=0
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

if [ "$ARGV" == "" ]; then
	usage
fi

#sort project in repo to bin search
for key in $ALL_PACKETS; do MAP[$key]="$key"; done  
# sync repo file to build path 
dolog "Force resync work repo"
rsync -ry $OREPO $REPO
if [ $? -ne 0 ]; then
	error_c "Cannot  sync work repository"
fi
configure_all_packet  $ARGV
}


#$1 step id build number ex : ./configire.sh 0 -> configure build step id==0
xml_get_env
main "$@"
