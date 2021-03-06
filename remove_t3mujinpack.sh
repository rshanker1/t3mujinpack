#!/bin/bash
# Removes all t3mujinpack styles from Darktable database.
#
# Author: João Almeida <info@joaoalmeidaphotography.com>

set -euo pipefail

# Initialize output colors
LIGHT_GREY='\033[0;37m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
LIGHT_BLUE='\033[1;34m'
NC='\033[0m' # No Color

echo ""
echo "----------------------------------------------------------------------"
echo -e "${LIGHT_GREY}t3mujinpack - Film emulation presets for Darktable 2.x"
echo ""
echo -e "Presets Uninstall script${NC}"
echo "----------------------------------------------------------------------"


# Validate Darktable installation

if [ ! -x "`which "darktable"`" ]
then
	echo ""
	echo -e "${YELLOW}Darktable is not installed.${NC}"
	echo ""
	exit 1
fi

# Setup database file

if [ "${1:-}" = "" ]
then
	echo ""
	echo "Using default database files"
	data_database_file="$HOME/.config/darktable/data.db"
	library_database_file="/$HOME/.config/darktable/library.db"
	if [ ! -f "$data_database_file" ]
	then
			data_database_file="/$HOME/.config/darktable/library.db"
	fi
else
	if [ "${2:-} " = "" ]
	then
		echo ""
		echo -e "${YELLOW}You must also specify the library database file${NC}"
		echo ""
		exit
	else
		echo "Using given database files"
		data_database_file="$1"
		library_database_file="$2"
	fi
	if [ ! -f "$data_database_file" ]
	then
			echo ""
			echo -e "${YELLOW}File $data_database_file does not exist${NC}"
			echo ""
			exit
	fi
fi

# Validate Darktable model

echo "Current metadata database file: $data_database_file"
echo "Current library database file: $library_database_file"

output_data=$(sqlite3 $data_database_file "select count(1) from sqlite_master where name = 'styles' or name = 'style_items' or name = 'tags'")

if [ $output_data != 3 ]
then
	echo ""
	echo -e "${YELLOW}$data_database_file is not an Darktable metadata database${NC}"
	echo "Execution has ended and presets have NOT been uninstalled!"
	echo ""
	exit 2
fi

output_library=$(sqlite3 $library_database_file "select count(1) from sqlite_master where name = 'tagged_images' or name = 'used_tags'")

if [ $output_library != 2 ]
then
	echo ""
	echo -e "${YELLOW}$library_database_file is not an Darktable library database${NC}"
	echo "Execution has ended and presets have NOT been uninstalled!"
	echo ""
	exit 2
fi

# Validate t3mujinpack instalation (including older version)

styles_list=`sqlite3 $data_database_file "select name from styles where name like 't3mujin - %' or name like 't3mujinpack - %' order by name"`


if [ "$styles_list" = "" ]
then
	echo ""
	echo -e "${YELLOW}t3mujinpack is not installed${NC}"
	echo ""
	exit 3
fi

# Review current styles

echo ""
echo "Installed t3mujinpack styles:"


for styles_list_current in $styles_list; do
	if [ "$styles_list_current" = "t3mujinpack" ] || [ "$styles_list_current" = "t3mujin" ]
	then
		echo ""
		echo -ne "\t"
	fi

	echo -ne "${LIGHT_BLUE}$styles_list_current ${NC}"

done

echo ""
echo ""
while true; do
    read -p "Do you wish to remove these styles? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo ""; echo "Styles removal cancelled"; echo ""; exit;;
        * ) echo "Please answer [y]es or [n]o.";;
    esac
done


# Execute uninstall

echo ""
echo -ne "\t Removing styles definitions... "
$(sqlite3 $data_database_file "delete from style_items where style_items.styleid in ( select id from styles where name like 't3mujin - %')")
$(sqlite3 $data_database_file "delete from style_items where style_items.styleid in ( select id from styles where name like 't3mujinpack - %')")
$(sqlite3 $data_database_file "delete from styles where name like 't3mujin - %'")
$(sqlite3 $data_database_file "delete from styles where name like 't3mujinpack - %'")

echo ""
echo ""
echo -ne "${GREEN}t3mujinpack presets have been uninstalled!${NC}"
echo ""
