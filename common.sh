#!/bin/bash

if ! command -v adb &> /dev/null
then
    echo "adb could not be found"
    exit
fi

if [ -z "$(adb devices | tail -n +2)" ]; then
    echo "No device found"
    exit
fi

# TODO: Add more packages
package_list=( "com.vivo.browser" "com.vivo.appstore" "com.vivo.easyshare" "com.vivo.website" "com.vivo.email" "com.bbk.cloud" "com.vivo.appstore" "com.vivo.website" )