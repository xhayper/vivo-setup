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

    # TODO: error handling
    adb shell pm uninstall -k --user 0 $package &> /dev/null

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