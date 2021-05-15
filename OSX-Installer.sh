#!/bin/bash

set -eu

# print heredoc
credits() {
cat << EOF

#################################################
#################################################
##                                             ##
##    RoulettePlus 2.0 installer by AzXeus     ##
##        (MacOS port by quietoctopus)         ##
##                                             ##
##  PatchUPK.exe used in the patching process  ##
##             Credits to WGhost81             ##
##                                             ##
#################################################
#################################################

EOF
}

# contants
XEW_INSTALL_DATA="XComData/XEW"

# :permissioncheck
permission_check() {
	testDir='installerPermissionCheck'
	mkdir ../${testDir} && rm -r ../${testDir} || { echo 'ERROR: unable to create files in current directory' ; exit 1; }
	echo '[OK] Script permissions confirmed'
}

# :inXEW
directory_check() {
	dgc_file="../${XEW_INSTALL_DATA}/XComGame/Config/DefaultGameCore.ini"
	if [ -e ${dgc_file} ]
		then
			echo '[OK] Install location verified'
		else
			echo 'Could not find DGC.ini (are the installation files in the correct folder?)'
			exit 1
	fi

	read -r dgc_line1 < ${dgc_file}
	# strip carriage return (Windows uses 'carriage return + line feed' for newline)
	dgc_line1=${dgc_line1%$'\r'}
	if [[ "$dgc_line1" != "; LONG WAR DGC.INI" ]]; then
		echo "The first line in DGC is not ${dgc_line1} (is LW installed?)"
		exit 1		
	else
		echo '[OK] LW installation detected'
	fi
}

cd -- "$(dirname "$0")"
BASE=$(pwd)
patch_dir="$BASE/Patch Files"
config_dir="$BASE/Config"
mod_dir="$BASE/Mods"

credits
permission_check
directory_check

# :start
gamefile_path="../${XEW_INSTALL_DATA}/XComGame"
gamepackages_path="${gamefile_path}/CookedPCConsole"
gameconfig_path="${gamefile_path}/Config"

echo 'Backing up game files...'
cp ${gamefile_path}/CookedPCConsole/XComGame.upk ./Backup
cp ${gamefile_path}/CookedPCConsole/XComStrategyGame.upk ./Backup

# find "$patch_dir" -type f -iname '*.txt' -exec echo "File: '{}'" \;
# :patch
patch_func() {
	file="$1"
	if [ -d $gamepackages_path ]; then
		if [ -f "$file" ]; then
			./PatchUPK "$file" ../XComData/XEW/XComGame/CookedPCConsole
			# printf '%s\n' "$gamepackages_path" 
		fi
	fi
}

# delete uninstall files from previous install if present
find "$patch_dir" -type f -wholename '*.uninstall*' -exec rm -f "{}" \;

export -f patch_func
# install XComModBridge first as per azxeus' post here --> https://www.nexusmods.com/xcom/mods/657/?tab=posts&BH=2
find "$patch_dir" -type f -wholename '*XComModBridge*' -exec bash -c 'patch_func "$1"' _ {} \;
find "$patch_dir" -type f -iname '*.txt' ! -wholename '*XComModBridge*' -exec bash -c 'patch_func "$1"' _ {} \;

if [ -d "$gamepackages_path" ]; then
	# echo '[OK] Xcom package dir found'
	if [ -d "${gamepackages_path}/Mods" ]; then
		# mod directory already exists
		find "$mod_dir" -type f -iname '*.u' -exec cp {} "${gamepackages_path}/Mods" \;
	else
		# move mods into preexisting Xcom package mod directory
		cp -R "$mod_dir" "${gamepackages_path}/Mods"
		echo "[OK] TRP mods added to ${gamepackages_path}/Mods"
	fi
else
	echo "WARNING -- ${gamepackages_path} does not exist!"
fi

if [ -d "$gameconfig_path" ]; then
	# echo '[OK] Xcom Config dir found'
	find "${config_dir}" -type f -iname '*.ini' -exec cp {} "$gameconfig_path" \;
	echo "[OK] TRP configs added to ${gameconfig_path}"
else
	echo "WARNING -- ${gameconfig_path} does not exist!"
fi

# ./PatchUPK



