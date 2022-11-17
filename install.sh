#! /bin/bash

# Note:
# 1. This file should be put into the kernel source tree root.
# 2. The source directory should be named as "*-VERSION.PATCHLEVEL.SUBLEVEL"
# 3. The (virtual) machine used for experiment compiled kernel should have a firmware type of "UEFI"

make modules_install

if [ ! -f "./arch/x86/boot/bzImage" ]; then
    echo "bzImage not exit."
    echo "runing make bzImage..."
    make bzImage
fi

current_work_dir=$(pwd)
parent_dir_name=$(basename $current_work_dir)

# get kernel version bits from the work dir name
# print details: just line string  concatenation in the cmd line: a constant string can be concatenated directly with variables
mid_expression=$(echo $parent_dir_name | gawk -F- '{print $2}' | gawk -F. '{print "a=\""$1"\"", "b=\""$2"\"", "c=\""$3"\""}')
eval $mid_expression

# here a,b,c gets the coresponding "VERSION,PATCHLEVEL,SUBLEVEL" bit of kernel version
# echo $a

my_kernel_name="linux"$a$b

echo "my new kernel name: " $my_kernel_name

new_vmlinuz_file_name="vmlinuz-"$my_kernel_name
cp -v ./arch/x86/boot/bzImage /boot/$new_vmlinuz_file_name

new_preset_file_name=$my_kernel_name".preset"
cp /etc/mkinitcpio.d/linux515.preset /etc/mkinitcpio.d/$new_preset_file_name

new_initramfs_file_name="initramfs-"$my_kernel_name".img"
new_fallback_initramfs_file_name="initramfs-"$my_kernel_name"-fallback.img"
# edit /etc/mkinitcpio.d/$my_kernel_name.preset according to new kernel
# Use double quotes to make the shell expand variables($new_vmlinuz_file_name,$new_initramfs_file_name...)
cat /etc/mkinitcpio.d/$new_preset_file_name | sed -e "s/^ALL_kver=.*$/ALL_kver=\/boot\/$new_vmlinuz_file_name/" \
    -e "s/^default_image=.*$/default_image=\/boot\/$new_initramfs_file_name/" \
    -e "s/^fallback_image=.*$/fallback_image=\/boot\/$new_fallback_initramfs_file_name/" \
   | tee /etc/mkinitcpio.d/$new_preset_file_name

# echo "new preset "$new_preset_file_name":"
# cat /etc/mkinitcpio.d/$new_preset_file_name

# Generate the initramfs images for the custom kernel in the same way as for an official kernel:
mkinitcpio -p $my_kernel_name
# mkinitcpio -k $a.$b.$c -g /boot/$new_initramfs_file_name

# Copy System.map
# The System.map file is not required for booting Linux. But it contains a list of kernel symbols(i.e function names, variable names etc) 
# and their corresponding addresses which is used by some processes

# Note: EFI system partitions are formatted using FAT32, which does not support symlinks.
# If your /boot is on a filesystem which supports symlinks (i.e. not FAT32), copy System.map to /boot, 
# appending your kernel's name to the destination file. 
# Then create a symlink from /boot/System.map to point to /boot/System.map-$my_kernel_name:

# get filesystem type of /boot
boot_fs_type=$(df -Th | grep /boot$ | gawk '{print $2}')

if [[ ! $boot_fs_type == *"fat"* ]]; then
  cp ./System.map /boot/System.map-$my_kernel_name
  ln -sf /boot/System.map-$my_kernel_name /boot/System.map
fi

grub-mkconfig -o /boot/grub/grub.cfg
# --efi-directory specifies the mount point of "EFI System Partition"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
update-grub

# You may need to create a EFI System Partition
# Choose one of the following methods to create an ESP for a MBR partitioned disk:
# 1. fdisk: Create a primary partition with partition type EFI (FAT-12/16/32).
# 2. GNU Parted: Create a primary partition with fat32 as the file system type and set the esp flag on it.
#    Note: set esp flag: [set n esp on] where n is the partition number which "print" shows.