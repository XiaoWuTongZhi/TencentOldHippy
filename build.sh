#
#  build_qbwebview.sh
#
#  Created by zuckchen on 9/9/16.
#  Copyright © 2016 zuckchen. All rights reserved.
#
set -e

cd "$(dirname "$0")"

if [[ ! -d $WORKSPACE ]]; then
	WORKSPACE=`pwd`
fi

if [[ -z $XCODE_PATH ]]; then
	XCODE_PATH=xcodebuild
fi

while getopts "c:" arg
do
        case $arg in
             c)
				customScheme=$OPTARG
                ;;
             ?)
        		;;
        esac
done

setWithConfiguartion()
{
	configuration=$1
	echo "configuration is ${configuration}"
}

doBuild()
{
	echo "remark is ${remark}"
	echo "BaseLine is ${BaseLine}"
	$XCODE_PATH -scheme $scheme -configuration $configuration archive -quiet

	if ! [ $? = 0 ] ;then
	exit 1
	fi
	sleep 3

	cp -r ~/Library/Developer/Xcode/Archives/`date +%Y-%m-%d`/$scheme\ *.xcarchive  $WORKSPACE/buildTemp/

	cd $WORKSPACE/buildTemp/

	#archive
	echo "start archive"
	zip xcarchive.zip -r $scheme\ *.xcarchive
	cp xcarchive.zip $WORKSPACE/result/"hippy-"${NumberVersion}"(GIT_"$GIT_REV")".zip

	#dSYM
	echo "start dSYM"
	cp -r $scheme\ *.xcarchive/dSYMs/$scheme.app.dSYM $scheme.app.dSYM
	zip symbol.zip -r $scheme.app.dSYM
	cp symbol.zip $WORKSPACE/result/$UniqueID.zip

	#ipa file
	echo "start create ipa"
	if [ $configuration = "Release" ];then
	$XCODE_PATH -exportArchive -exportOptionsPlist $WORKSPACE/BuildSettings/DailyBuildExportOptions.plist -archivePath $WORKSPACE/buildTemp/$scheme\ *.xcarchive -exportPath $WORKSPACE/buildTemp/
	fi

	echo $prefix$remark

	cp $WORKSPACE/buildTemp/*.ipa $WORKSPACE/result/"hippy-"${NumberVersion}.ipa

	echo "end build project"
}

build()
{
	#remove DerivedData folder if exists
	if [[ -d $derivedDataPath ]]; then
		rm -r $derivedDataPath
	fi

	if [[ -d "build" ]]; then
		rm -r "build"
	fi

	if [[ -z $configuration ]]; then
		setWithConfiguartion Release
	else
		setWithConfiguartion $configuration
	fi

	doBuild
}

cleanAndPrepareDirs()
{
	if [ -e ~/Library/Developer/Xcode/Archives/`date +%Y-%m-%d`/ ];then
	#rm -r ~/Library/Developer/Xcode/Archives/`date +%Y-%m-%d`/mttdailybuild\ *.xcarchive
	rm -r ~/Library/Developer/Xcode/Archives/`date +%Y-%m-%d`/
	echo "remove archives exist"
	fi

	if  [ -e $WORKSPACE/result ] ;then
	rm -r $WORKSPACE/result
	echo "clean result dir"
	fi

	if [ -e $WORKSPACE/buildTemp ] ;then
	rm -r $WORKSPACE/buildTemp
	echo "clean buildTemp dir"
	fi

	mkdir $WORKSPACE/result
	mkdir $WORKSPACE/buildTemp
}

if [[ -z $customScheme ]]; then
	echo "No Define Custom Scheme!!!"
	scheme=Hippy
else
	echo "Use Custom Scheme $customScheme!!!"
	scheme=$customScheme
fi

derivedDataPath=$scheme"_Output"
targetPath="${derivedDataPath}/${scheme}"

if [[ -z $productName ]]; then
	productName=$scheme
else
	productName=$productName
fi

echo "scheme is ${scheme}"
echo "derivedDataPath is ${derivedDataPath}"
echo "targetPath is ${targetPath}"
echo "productName is ${productName}"

cleanAndPrepareDirs

build

cd $WORKSPACE

echo "Build Successfully!!!"


