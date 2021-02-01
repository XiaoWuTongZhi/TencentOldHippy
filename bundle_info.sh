#
#  bundle_info.sh
#  mtt
#
#  Created by allensun on 13-10-3.
#  Copyright (c) 2013年 Tencent. All rights reserved.
#
#  将HotVideo/MttBundleInfo.plist里面的bundle属性值拷贝给资源文件

#FullBundleVersion
fullBundleVersionFromPlist=$(/usr/libexec/PlistBuddy -c "Print :FullBundleVersion" demo/MttBundleInfo.plist)

fullBundleVersion=${NumberVersion:-$fullBundleVersionFromPlist}

if [ $fullBundleVersionFromPlist != $NumberVersion ]; then
/usr/libexec/PlistBuddy -c "Set :FullBundleVersion $NumberVersion" demo/MttBundleInfo.plist
fi

#sed -i '' "s/<!--FullBundleVersion-->.*<!---->/<!--FullBundleVersion-->$fullBundleVersion<!---->/g" res/about/about.html
#sed -i '' "s/<!--FullBundleVersion-->.*<!---->/<!--FullBundleVersion-->$fullBundleVersion<!---->/g" res/about/help.html

#ShortBundleVersion

#devide the fullBundleVersion with dot
OLD_IFS="$IFS"
IFS="."
arr=($fullBundleVersion)
IFS="$OLD_IFS"

#write into plist
if [ $BuildNo ]; then
/usr/libexec/PlistBuddy -c "Set :BuildNo $BuildNo" demo/MttBundleInfo.plist
fi

if [ $LC ] && [ $APPID ]; then
/usr/libexec/PlistBuddy -c "Set :LC $LC" demo/MttBundleInfo.plist
/usr/libexec/PlistBuddy -c "Set :LCID $APPID" demo/MttBundleInfo.plist
fi

if [ $VE ]; then
/usr/libexec/PlistBuddy -c "Set :VE $VE" demo/MttBundleInfo.plist
fi

files=(
demo/Info.plist
)

#when 3rd part of fullBundleVersion is zero, it will be skipped
# bundle version update in this shell script can only update the main project app(mttlite)
# if you want to update extensions or watch apps' bundle version, please add proper plist file paths in build.sh
for i in "${files[@]}"
do
    echo "$i"

    if [ "$BuildNo" ]; then
        shortBundleVersion=${arr[0]}.${arr[1]}.${arr[2]}
        echo "update CFBundleVersion"
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $shortBundleVersion.$BuildNo" "$i"
    else
        shortBundleVersion=${arr[0]}.${arr[1]}.${arr[2]}
        echo "update CFBundleVersion/CFBundleShortVersionString/CFBundleInfoDictionaryVersion"
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $shortBundleVersion" "$i"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $shortBundleVersion" "$i"
        /usr/libexec/PlistBuddy -c "Set :CFBundleInfoDictionaryVersion $shortBundleVersion" "$i"
    fi

    if [ "$shortBundleVersion" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $shortBundleVersion" "$i"
    fi

done

echo 'buildNo-${BuildNo}, shortBundleVersion-${shortBundleVersion}'


#ChannelId
#channelId=$(/usr/libexec/PlistBuddy -c "Print :ChannelId" HotVideo/MttBundleInfo.plist)

#/usr/libexec/PlistBuddy -c "Set :ChannelId $channelId" ChannelInfo.plist


#ReleaseDate
releaseDate=$(date +%Y-%m-%d)

#sed -i '' "s/<!--ReleaseDate-->.*<!---->/<!--ReleaseDate-->$releaseDate<!---->/g" res/about/about.html
#sed -i '' "s/<!--ReleaseDate-->.*<!---->/<!--ReleaseDate-->$releaseDate<!---->/g" res/about/help.html


#TestEnvironment
isTestEnvironment=0
if [ "$TestEnvironment" == 1 ]; then
isTestEnvironment=1
fi

/usr/libexec/PlistBuddy -c "Set :TestEnvironment $isTestEnvironment" demo/MttBundleInfo.plist


#NewFeatures
#featureIndex=1
#unset featureResult

#features=$(/usr/libexec/PlistBuddy -c "Print :NewFeatures" HotVideo/MttBundleInfo.plist)

#for feature in $features; do
#if [ $feature != "Array" ] && [ $feature != "{" ] && [ $feature != "}" ]; then
#featureResult=${featureResult}"<li><span class=\"order\">"$featureIndex".<\/span>"$feature"<\/li>"
#let featureIndex+=1
#fi
#done

#sed -i '' "s/<!--NewFeatures-->.*<!---->/<!--NewFeatures-->$featureResult<!---->/g" res/about/about.html

