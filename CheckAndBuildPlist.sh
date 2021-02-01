#!/bin/sh
#by kingjlhuang#tencent.com


build() {
    echo "Building $1 ..."
    sh build_plist.sh $1
}

checkAndBuild() {
    shouldRunPlistShell=0

    themePath=HotVideo/res/themes/$1
    resPath=$themePath/res

    themeModifyDate=`stat -f%m $themePath`
    resModifyDate=`stat -f%m $resPath`
    modifyDate="$themeModifyDate$resModifyDate"

    #make sure the config file exist and initailized correctly
    configFilePath=HotVideo/res/themes/.ThemeModifyDate
    if [ ! -f $configFilePath ]; then
        touch $configFilePath
    fi

    lastModifyDate="`sed '/^'$1'=/!d;s/.*=//' ${configFilePath}`"
    if [ ! $lastModifyDate ]; then
        lastModifyDate="0"
        shouldRunPlistShell=1
    fi

    #check whether if the file has been modified since last update
    if [ "$modifyDate" != "$lastModifyDate" ]; then
        shouldRunPlistShell=1
    else
        echo "No update for $1, no build"
    fi
    
    #excute the build shell
    if [ $shouldRunPlistShell = 1 ]; then
        build $1
        sed -i "" '/^'$1'=/d' ${configFilePath} #remove the line
        echo "$1=$modifyDate" >> $configFilePath #add new line
    fi
}

################### START ####################
if [ "${CONFIGURATION}" = "Debug" ]; then
    checkAndBuild $1
else
    build $1
fi