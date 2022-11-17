#! /bin/bash

# This file should be put into the kernel source tree root.
# The source directory should be named as "*-VERSION.PATCHLEVEL.SUBLEVEL"

# print work directory
current_work_dir=$(pwd)
parent_dir_name=$(basename $current_work_dir)
build_dir="../"$parent_dir_name"-build"

if [ -d "$build_dir" ]; then
    echo $build_dir "exist."
else
    mkdir "$build_dir"
fi

echo "buiding into" $build_dir

# build files into specific build directory
MAKE="make o="$build_dir

$MAKE mrproper

# generate and alter .config 
zcat /proc/config.gz > .config
./scripts/config --disable CONFIG_MODULE_SIG_KEY

# get kernel version bits from the work dir name
# print details: just line string  concatenation in the cmd line: a constant string can be concatenated directly with variables
mid_expression=$(echo $parent_dir_name | gawk -F- '{print $2}' | gawk -F. '{print "a=\""$1"\"", "b=\""$2"\"", "c=\""$3"\""}')
eval $mid_expression

# here a,b,c gets the coresponding version bit of kernel
# echo $a

# This option should be changed before each buiding
now_time=$(date -d "now" +%m-%d)
new_local_version=$a"."$b"-marting-"$now_time

# record in file
echo $new_local_version > new_local_version.txt

./scripts/config --set-val CONFIG_LOCALVERSION $new_local_version
./scripts/config --enable CONFIG_LOCALVERSION_AUTO

# To accept the defaults without being prompted
make olddefconfig
# ./aur-install.sh modprobed-db
# make LSMOD=$HOME/.config/modprobed.db localmodconfig

$MAKE -j8

$MAKE modules


