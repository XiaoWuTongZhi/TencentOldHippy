#!/bin/bash

#interupted if error occurs
set -e

if [[ -z $customScheme ]]; then
	echo "No Define Custom Scheme!!!"
	scheme=Hippy
else
	echo "Use Custom Scheme $customScheme!!!"
	scheme=$customScheme
fi

SDK=$compileEnv
XCODE_PATH=$XCODE_PATH$compileEnv

echo `pwd`
echo "productName is ${productName}"
echo "scheme is ${scheme}"
echo "SDK is ${SDK}"
echo "XCODE_PATH is ${XCODE_PATH}"
echo "WORKSPACE is ${WORKSPACE}"
GIT_REV=$(git rev-parse HEAD)

build()
{
	# cd ${WORKSPACE}/HotVideo

	customScheme=$scheme GIT_REV=$GIT_REV WORKSPACE=$WORKSPACE configuration=$configuration productName=$productName XCODE_PATH=$XCODE_PATH sh ./build.sh
}

# source bundle_info.sh

if [[ -z $CI_PUSH_CHECK ]]; then
	build
fi

# bold=$(tput bold)
# normal=$(tput sgr0)
# echo "${bold}build SDK successfully!!!\n${normal}"
