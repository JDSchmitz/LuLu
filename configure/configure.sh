#!/bin/sh

#
#  file: configure.sh
#  project: lulu (configure)
#  description: install/uninstall 
#
#  created by Patrick Wardle
#  copyright (c) 2017 Objective-See. All rights reserved.
#

#for now, gotta be macOS 10.12+
OSVers=`sw_vers -productVersion`
if [[ ${OSVers:3:2} -lt 12 ]]; then
 echo "\nERROR:" $OSVers "is currently unsupported"
 echo "LuLu requires macOS 10.12+\n"
 exit -1
fi

#gotta be root
if [ "$EUID" -ne 0 ]; then
 echo "\nERROR: must be run as root\n"
 exit -1
fi


if [ "$1" == "-install" ]
then
    echo "installing"

    #remove all xattrs
    /usr/bin/xattr -rc *

    #main LuLu directory
    mkdir -p /Library/Objective-See/LuLu

    #rules
    chown root:wheel rules.plist
    chmod 700 rules.plist
    cp rules.plist /Library/Objective-See/LuLu/

    #install & load kext
    chown -R root:wheel LuLu.kext
    cp -R LuLu.kext /Library/Extensions/
    kextload /Library/Extensions/LuLu.kext

    echo "kext installed and loaded"

    #install & load launch daemon
    chown -R root:wheel LuluDaemon
    cp LuluDaemon /Library/Objective-See/LuLu/
    cp com.objective-see.lulu.plist /Library/LaunchDaemons/
    launchctl load /Library/LaunchDaemons/com.objective-see.lulu.plist

    echo "launch daemon installed and loaded"

    #install & load main app/helper app
    cp -R LuLu.app /Applications
    /Applications/LuLu.app/Contents/MacOS/LuLu "-install"

    echo "install complete"

    exit 1

elif [ "$1" == "-uninstall" ]
then

    echo "uninstalling"

    #unload & remove kext
    kextunload -b com.objective-see.lulu
    rm -rf /Library/Extensions/LuLu.kext

    echo "kext unloaded and removed"

    #unload launch daemon & remove plist
    launchctl unload /Library/LaunchDaemons/com.objective-see.lulu.plist
    rm /Library/LaunchDaemons/com.objective-see.lulu.plist

    echo "unloaded launch daemon"

    #uninstall & remove main app/helper app
    /Applications/LuLu.app/Contents/MacOS/LuLu "-uninstall"
    rm -rf /Applications/LuLu.app

    #delete LuLu's folder
    # contains launch daemon, rules, etc
    rm -rf /Library/Objective-See/LuLu/

    #kill
    killall "LuLu" 2> /dev/null
    killall "com.objective-see.luluHelper" 2> /dev/null
    killall "LuLu Helper" 2> /dev/null


    echo "uninstall complete"

    exit 1

fi

#invalid args
echo "\nERROR: run w/ '-install' or '-uninstall'\n"
exit -1
