#!/bin/bash

source common.sh

backup_package () {
    local package=$1

    local installed_packages=($(adb shell pm list packages | sed -e "s/^package://"))

    if [[ ! " ${installed_packages[@]} " =~ " ${package} " ]]; then
        echo "Package $package not installed, not creating a backup!"
        return
    fi

    mkdir -p backup/$package

    echo "Backing up $package"

    local files=($(adb shell pm path $package | sed -e "s/^package://"))

    for file in ${files[@]}; do
        # TODO: error handling
        adb pull $file "backup/$package/" &> /dev/null
    done

    echo "Backed up $package"
}

uninstall_package () {
    local package=$1

    local installed_packages=($(adb shell pm list packages | sed -e "s/^package://"))

    if [[ ! " ${installed_packages[@]} " =~ " ${package} " ]]; then
        echo "Package $package not installed, not uninstalling!"
        return
    fi

    echo "Uninstalling $package"
    uninstall_result=($(adb shell pm uninstall -k --user 0 $package))

    if [[ $uninstall_result == Failure* ]]; then
        echo "Uninstalling with --user 0 failed, trying other method"
        
        local android_ver=($(adb shell getprop ro.build.version.release))

        if [[ $android_ver == 13 ]]; then
            uninstall_result=($(adb shell service call package 131 s16 $package i32 0 i32 0))
        elif [[ $android_ver == 12 ]]; then
            uninstall_result=($(adb shell service call package 134 s16 $package i32 0 i32 0))
        fi

        # Thank you Github Copilot for the following code

        uninstall_result=${uninstall_result#*Parcel(}
        uninstall_result=${uninstall_result//$'\n'/}
        uninstall_result=(${uninstall_result// / })

        if [[ " ${uninstall_result[@]} " =~ " 00000000 " && " ${uninstall_result[@]} " =~ " 00000001 " ]]; then
            echo "Uninstalled $package"
            return
        else
            echo "Uninstalling $package failed"
            return
        fi
    fi

    echo "Uninstalled $package"
}


while true; do
    printf "Do you want to backup packages? [y/n]: "
    read backup
    if [ "$backup" != "${backup#[YyNn]}" ] ;then
        break
    fi
done

if [ "$backup" != "${backup#[Yy]}" ] ;then
    echo "Backing up packages"
    
    for package in ${package_list[@]}; do
        backup_package $package
    done

    echo "Done"
else
    echo "Not backing up packages"
fi

while true; do
    printf "Are you sure you want to uninstall packages? [y/n]: "
    read uninstall
    if [ "$uninstall" != "${uninstall#[YyNn]}" ] ;then
        break
    fi
done

if [ "$uninstall" != "${uninstall#[Yy]}" ] ;then
    echo "Uninstalling packages"

    for package in ${package_list[@]}; do
        uninstall_package $package
    done

    echo "Done"
else
    echo "Aborting"
    exit
fi