#!/bin/sh

# include io functions
source "$(pwd)/functions.sh"


function main(){
local ALL_PACKET="rsync wget svn git apt apt-get xmlstarlet make gcc "

for i in $ALL_PACKET
do
which $i > /dev/null
if [ $? -eq 1 ]; then
	print_c "$RED_LIGHT" " have to install :" 
	print_c "$YELLOW" "\t\t$i -> sudo apt install $i "
else
	print_c "$GREEN_LIGHT" "   - $i : " 
	print_c "$YELLOW" "\t\t\t\tOK!"
fi

done
}


main
