#!/bin/sh 

if [ "$OROOT" == "" ] ; then
	OROOT="$HOME/eggX"
fi

SCRIPT_DIR=$OROOT/scripts
OREPO=$OROOT/repo/.

# include configuration
source "$SCRIPT_DIR/conf.sh"
# include io functions
source "$SCRIPT_DIR/functions.sh"

#initial value PATH
RESPATH="/usr/bin:/sbin:/bin"
MYPATH=""

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


#$1 build name
#$2 dir
function remove_path(){
local V=$(echo $MYPATH | sed -e 's/:/  /g')
local OLD=$IMAGES/$1/$2
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
local NEW=$IMAGES/$1/$2
local V=$(echo $MYPATH | sed -e 's/:/  /g')
for I in $V; do
	if [ "$I" == "$NEW" ]; then
		return 
	fi
done
MYPATH="$NEW:"$MYPATH
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
				if [ "$BUILD_NAME" == "" ]; then 
					BUILD_NAME=$NAME
				else
					if [ "$BUILD_NAME" != "$NAME" ]; then
						error_c "Misaligned project name " "  -project $1 : step $2"
					fi
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
				INDEX="$PRI%$NAME%$ARCH%$CROSS:$1%$SILENT%$THREADS%$PREFIX"
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
				xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path_pre"
				NUM=$?
				if [ $NUM -ne 0 ]; then 	
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path_pre/remove"
					NUM=$?
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path_pre/add"
					MAX=$?
					if [ $NUM -gt $MAX ]; then
						MAX=$NUM
					fi					
					ID=0
					while [ $ID -lt $MAX ]; do
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path_pre/remove[@id=\"$ID\"]")
						if [ "$TPATH" != "" ]; then
							remove_path $NAME $TPATH
						fi
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path_pre/add[@id=\"$ID\"]")
						if [ "$TPATH" != "" ]; then
							add_path $NAME $TPATH
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
				xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path_post"
				NUM=$?
				if [ $NUM -ne 0 ]; then 	
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path_post/remove"
					NUM=$?
					xml_count $1 "/egg/project/build/step[@id=\"$2\"]/path_post/add"
					MAX=$?
					if [ $NUM -gt $MAX ]; then
						MAX=$NUM
					fi					
					ID=0
					while [ $ID -lt $MAX ]; do
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path_post/remove[@id=\"$ID\"]")
						if [  "$TPATH"  !=  ""  ]; then
							remove_path $NAME $TPATH
						fi
						TPATH=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/path_post/add[@id=\"$ID\"]")
						if [  "$TPATH"  !=  ""  ]; then
							add_path $NAME $TPATH
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
#$7 prefix
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
	echo "export PATH=$MYPATH" >> "$3"
	echo "export PROJECT=$1" >> "$3"
	echo "export SOURCES=$SOURCES" >> "$3"
	echo "export BUILDS=$BUILD/$4">> "$3"
	echo "export SOURCE=$SRC" >> "$3"
	echo "export BUILD=$BUILD/$4/$1/build" >> "$3"
	echo "export DEPLOY=$7" >> "$3"
	echo "export ARCH=$5">> "$3"
	echo "export CROSS=$6">> "$3"
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
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/pre_conf"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/pre_conf[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre conf id=$i value Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/pre_conf[@id=\"$i\"]/mode")	
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
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/post_conf"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/post_conf[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post conf id=$i Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/pre_conf[@id=\"$i\"]/mode")	
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
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/extra_conf"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/extra_conf[@id=\"$i\"]")	
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
		if  [ "$4" == "yes" ]; then 
			echo " > /dev/null" >>  $3
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
#$8 thread
#$9 prefix
function add_build_script(){
generate_setenv "$1" "$2" "$3/setenv.sh" "$4" "$5" "$6" "$9"
local SH_CLEAN="$3/clean.sh"
local SH_DISTCLEAN="$3/distclean.sh"
local SH_BUILD="$3/build.sh"
local SH_INSTALL="$3/install.sh"
local SH_REBUILD="$3/rebuild.sh"
rm -f "$SH_CLEAN" "$SH_DISTCLEAN" "$SH_BUILD" "$SH_INSTALL" "$SH_REBUILD" 
touch "$SH_CLEAN" "$SH_DISTCLEAN" "$SH_BUILD" "$SH_INSTALL" "$SH_REBUILD"
chmod +rwx "$SH_CLEAN" "$SH_DISTCLEAN" "$SH_BUILD" "$SH_INSTALL" "$SH_REBUILD"
# clean 
prepare_script_generic "$1" "$2" "Start clean build " "$SH_CLEAN" "$4" "$5" "$6"
echo "if [ -f Makefile ]; then " >> "$SH_CLEAN"
echo " make -C \$BUILD clean " >> "$SH_CLEAN"
echo "fi" >> "$SH_CLEAN"
echo "" >> "$SH_CLEAN"
echo "" >> "$SH_CLEAN"
end_script_generic "$1" "$2" "done clean build " "$SH_CLEAN"
#distclean 
prepare_script_generic "$1" "$2" "Start distclean build " "$SH_DISTCLEAN" "$4" "$5" "$6"
echo "cd \$PWD " >> "$SH_DISTCLEAN"
echo "rm -rf \$BUILD " >> "$SH_DISTCLEAN"
echo "" >> "$SH_DISTCLEAN"
echo "" >> "$SH_DISTCLEAN"
end_script_generic "$1" "$2" "done distclean build " "$SH_DISTCLEAN"
#build
prepare_script_generic "$1" "$2" "Start build " "$SH_BUILD" "$4" "$5" "$6"
#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
add_pre_build "$1" "$2" "$SH_BUILD" "$3" "$4"
#$1 project
#$2 build path
#$3 file out
#$3 silent 
#S4 threads
add_entry_in_main_build_script "$1" "$3"  "$SH_BUILD" "$7" "$8"
#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
add_post_build "$1" "$2" "$SH_BUILD" "$3" "$4"
end_script_generic "$1" "$2" "done  build " "$SH_BUILD"
#install
prepare_script_generic "$1" "$2" "Start install " "$SH_INSTALL" "$4" "$5" "$6"
#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
add_pre_install "$1" "$2" "$SH_INSTALL" "$3" "$4"
#$1 project
#$2 build path
#$3 file out
#$3 silent 
add_entry_in_main_install_script "$1" "$3"  "$SH_INSTALL" "$7" 
#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
add_post_install "$1" "$2" "$SH_INSTALL" "$3" "$4"
end_script_generic "$1" "$2" "done  install " "$SH_INSTALL"
#rebuild
prepare_script_generic "$1" "$2" "Start Rebuild " "$SH_REBUILD" "$4" "$5" "$6"
echo "$SH_CLEAN" >> "$SH_REBUILD"
echo "$SH_DISTCLEAN" >> "$SH_REBUILD"
echo "$3/bootstrap.sh" >> "$SH_REBUILD"
echo "$SH_BUILD" >> "$SH_REBUILD"
echo "$SH_INSTALL" >> "$SH_REBUILD"
end_script_generic "$1" "$2" "done  rebuild " "$SH_REBUILD"
}

#$1 project
#$2 step id
#$3 file out
#$4 path build
#$5 build name
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
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/pre_build"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/pre_build[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre build id=$i value Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/pre_build[@id=\"$i\"]/mode")	
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
function add_pre_install(){
declare -i i=0
local VALUE=""
local MODE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action pre_install"	
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/pre_install"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/pre_install[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre install id=$i value Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/pre_install[@id=\"$i\"]/mode")	
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  pre install id=$i mode Phase $2" "project : $1"
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
					error_c "Unknow  pre install id=$i mode Phase $2" "project : $1"
					;;
				esac				
				i=$((i+1))
				done 
			else
				echo "# no pre build script available for prject : $1" >> $3
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
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/post_build"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/post_build[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post build id=$i Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/post_build[@id=\"$i\"]/mode")	
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
#$2 step id
#$3 file out
#$4 path build
#$5 build name
function add_post_install(){
declare -i i=0
local VALUE=""
check_project $1
if [ $? -eq 1 ]; then
	if [ -f $REPO/$1/conf.egg ]; then
		dolog "Read conf.egg from project $1 : action post_install"	
		xml_count $1 "/egg/project/build/step[@id=\"$2\"]"
		NUM=$?
		if [ $NUM -ne 0 ]; then
			xml_count $1 "/egg/project/build/step[@id=\"$2\"]/post_install"
			NUM=$?
			if [ $NUM -ne 0 ]; then
				while  [ $i -lt $NUM ]; do
				VALUE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/post_install[@id=\"$i\"]/value")	
				equs "$VALUE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post install id=$i Phase $2" "project : $1"
				fi
				MODE=$(xml_value $1 "/egg/project/build/step[@id=\"$2\"]/post_install[@id=\"$i\"]/mode")	
				equs "$MODE"  
				if [ $? -eq 1 ]; then 
					error_c "Missing  post install id=$i mode Phase $2" "project : $1"
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
					error_c "Unknow  post install id=$i mode Phase $2" "project : $1"
					;;
				esac				
				i=$((i+1))
				done 
			else
				echo "# no post install script available for prject : $1" >> $3
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
#S5 threads
function add_entry_in_main_build_script(){
if [ "$4" == "yes" ]; then 
	echo "make --silent -C \$BUILD -j$5 \$1 > /dev/null" >> "$3"
else
	echo "make -C \$BUILD  -j$5 \$1">> "$3"
fi
echo "if [ \$? -ne 0 ]; then">> "$3"
echo "    error_c \"Error on build \" \"  - project \$1\"" >>"$3"
echo "fi"  >> "$3"
}

#$1 project
#$2 build path
#$3 file out
#$4 silent 
function add_entry_in_main_install_script()
{
#install
if [ "$4" == "yes" ]; then 
	echo "make --silent -C \$BUILD   install > /dev/null" >> "$3"
else
	echo "make -C \$BUILD  install">> "$3"
fi
echo "if [ \$? -ne 0 ]; then">> "$3"
echo "    error_c \"Error on install \" \"  - project \$1\"" >>"$3"
echo "fi"  >> "$3"
}
#$1 id 0,1,2,3
#$2 composite name priority%name%arch%cross:project%silent%threads
function configure_packet(){
#retrieve data...
local PRIORITY=""
local BUILD_ARCH=""
local BUILD_CROSS=""
local BUILD_PROJECT=""
local BUILD_SILENT=""
local BUILD_THREADS=""
local AA=$(echo $2 | sed -e 's/%/   /g' | sed -e 's/:/   /g' )
PRIORITY=$(echo $AA | awk '{print $1}')
BUILD_ARCH=$(echo $AA | awk '{print $3}')
BUILD_CROSS=$(echo $AA | awk '{print $4}')
BUILD_PROJECT=$(echo $AA | awk '{print $5}')
BUILD_SILENT=$(echo $AA | awk '{print $6}')
BUILD_THREADS=$(echo $AA | awk '{print $7}')
BUILD_PREFIX=$(echo $AA | awk '{print $8}')
local CONF_RUN="$BUILD/$BUILD_NAME/$BUILD_PROJECT/bootstrap.sh"
local DEST="$IMAGES/$BUILD_NAME"
mkdir -p $BUILD/$BUILD_NAME/$BUILD_PROJECT
rm -rf $BUILD/$BUILD_NAME/$BUILD_PROJECT/*
mkdir -p $BUILD/$BUILD_NAME/$BUILD_PROJECT/build
mkdir -p $DEST
rm -rf $DEST/*
touch $CONF_RUN
chmod +x $CONF_RUN 
if [ $BUILD_PREFIX ]; then
	DEST="$DEST/$BUILD_PREFIX"
	mkdir -p $DEST
fi
manage_path_pre  $BUILD_PROJECT  $1
prepare_script_generic "$BUILD_PROJECT"  "$1" "START CONFIGURE" "$CONF_RUN" "$BUILD_NAME" "$BUILD_ARCH" "$BUILD_CROSS"
add_pre_conf "$BUILD_PROJECT" "$1" "$CONF_RUN" "$BUILD/$BUILD_NAME/$BUILD_PROJECT"  "$BUILD_NAME"
BTARGET=$(echo $BUILD_CROSS  | tr '[:lower:]' '[:upper:]')
if [ "$BTARGET" == "NATIVE" ]; then
	BTARGET=""
else
	BTARGET="--target=$BUILD_CROSS"
fi
EXTSI=$(echo $BUILD_SILENT  | tr '[:lower:]' '[:upper:]')
if [ "$EXTSI" != "YES" ]; then
	echo "set -x ">> $CONF_RUN
fi
if [ -e $SOURCES/$BUILD_PROJECT/configure ]; then
	echo -n "$SOURCES/$BUILD_PROJECT/configure  --prefix=$DEST $BTARGET ">> $CONF_RUN
else
	if [ -e $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure ]; then
		AA=$(ls $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure)
		echo -n "$AA  --prefix=$DEST $BTARGET ">> $CONF_RUN
	else
		if [ -e $SOURCES/$BUILD_PROJECT/configure.ac ]; then
			echo -n "$SOURCES/$BUILD_PROJECT/configure  --prefix=$DEST $BTARGET ">> $CONF_RUN
		else
			if [ -e $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure.ac ]; then
				AA=$(ls $SOURCES/$BUILD_PROJECT/$BUILD_PROJECT-*/configure)
				echo -n "$AA  --prefix=$DEST $BTARGET">> $CONF_RUN
			else
			error_c "Cannot locate configure script" "  - project $BUILD_PROJECT"
			fi
		fi
	fi
fi	
add_extra_conf "$BUILD_PROJECT" "$1" "$CONF_RUN"  "$BUILD_SILENT"
BTARGET=$(echo $BUILD_SILENT  | tr '[:lower:]' '[:upper:]')
iEXTSI=$(echo $BUILD_SILENT  | tr '[:lower:]' '[:upper:]')
if [ "$EXTSI" != "YES" ]; then
	echo "set +x ">> $CONF_RUN
fi
add_post_conf "$BUILD_PROJECT" "$1" "$CONF_RUN" "$BUILD/$BUILD_NAME/$BUILD_PROJECT"  "$BUILD_NAME"
end_script_generic  "$BUILD_PROJECT"  "$1" "END CONFIGURE" "$CONF_RUN"
add_build_script "$BUILD_PROJECT" "$1"  "$BUILD/$BUILD_NAME/$BUILD_PROJECT"  "$BUILD_NAME" "$BUILD_ARCH" "$BUILD_CROSS" "$BUILD_SILENT" "$BUILD_THREADS" "$DEST"
manage_path_post $BUILD_PROJECT  $1
sync
}








#$1 force 0=0ff 99 0=on
#$2.... 1=build id number 2 argv optional
function configure_all_packet(){
local V=""
local ID=$2
local PRJS=""
if [ $1 -eq  0 ]; then
	PRJS=$ALL_PACKETS
else
	shift 
	shift
	PRJS=$@
fi

for V in $PRJS; do
	insert_packet $V $ID 
done
SORTREQ=$(echo ${BSEQ[*]}| tr " " "\n" | sort -n )
MYPATH=$RESPATH
for V in $SORTREQ; do
	configure_packet  $ID $V
done
}



function usage(){
	print_c "$BLUE_LIGHT" "usage : ./configure.sh <opt> <phase=always> <args>"
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-D or --debug : set debug mode" 
	print_c  "$YELLOW" "OPTIONS" "$GREEN" "-F or --force : set debug mode"
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
		-F|--force)
		FORCE=99
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

if [ $FORCE -eq 0 ] && [ ${#ARGV[@]} -gt 1 ]; then
	warning_c "Discarding extra args on command line :\n to force a specific project(s) have to set\n --force flag , ex: :/configure.sh -F 2 binutils"
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
configure_all_packet  "$FORCE" $ARGV
}


#$1 step id build number ex : ./configire.sh 0 -> configure build step id==0

main "$@"
