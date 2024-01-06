#!/bin/bash

source common.sh

restore_package () {
    local package=$1

    local installed_packages=($(adb shell pm list packages | sed -e "s/^package://"))

    if [[ " ${installed_packages[@]} " =~ " ${package} " ]]; then
        echo "Package $package already installed, skipping!"
        return
    fi

    if [[ ! -d "backup/$package" ]]; then
        echo "Package $package not backed up, skipping!"
        return
    fi

    echo "Restoring $1"

    local files=($(ls backup/$package))

    for i in "${!files[@]}"; do
        files[$i]="backup/$package/${files[$i]}"
    done

    # TODO: error handling
    adb install-multiple -r ${files[@]} &> /dev/null

    echo "Restored $1"
}

echo "Restoring packages"

for package in ${package_list[@]}; do
    restore_package $package
done

echo "Done"