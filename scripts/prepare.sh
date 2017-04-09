#!/bin/sh

# include io functions
source "$(pwd)/functions.sh"


function main(){
local ALL_PACKET="rsync wget svn git apt apt-get xmlstarlet make gcc libtool autoconf glibc-static glibc-devel glibc-static libstdc++ libstdc++-devel autogen"

for i in $ALL_PACKET
do
AA=$(apt list --installed $i | grep $i )
if [ "$AA" == "" ]; then
	AA=$(which $i)
	if  [ "$AA" == "" ]; then 
	print_c "$RED_LIGHT" " have to install :" 
	print_c "$YELLOW" "\t\t$i -> sudo apt install $i "
	else
		print_c "$GREEN_LIGHT" "   - $i : $AA" 
		print_c "$YELLOW" "\t\t\t\tOK!"	
	fi
else
	print_c "$GREEN_LIGHT" "   - $i : $AA" 
	print_c "$YELLOW" "\t\t\t\tOK!"
fi

done
}


main
