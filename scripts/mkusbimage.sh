#!/bin/bash
#
# helper script to build a USB stick image
#
# (C) 2011, 2013 Stefan Seyfried
#     License: GPL v2
#
# * the kernel Image has to already exist in build_tmp
# * a rootfs (target minimal-system-pkgs or system-pkgs) has to
#   exist in build_tmp/install
#
# The image will have two partitions:
# * partition 1, fat16 ~15MB for the kernel
# * partition 2, ext3, the root fs
#
# the size in million bytes, hopefully smaller than the USB stick ;)
SIZE=500

#set -x
# get PLATFORM from the config file...
eval `sed -n '/^PLATFORM[[:space:]*]=/{s/[[:space:]*]//g;p}' config 2>/dev/null`
if [ x$PLATFORM = xspark ]; then
	if ! [ -d build_tmp/sparksystem ]; then
		echo "ERROR: please run 'make spark-system-usb' first."
		echo
		exit 1
	fi
fi

# hack for people who don't have sbin in $PATH
if ! echo $PATH | grep -q /sbin; then
	PATH=/sbin:/usr/sbin:/usr/local/sbin:$PATH
	export PATH
fi

# create the empty image (sparse, to save time)
rm -f build_tmp/usb.img
dd if=/dev/zero of=build_tmp/usb.img bs=1 count=1 seek=$(($SIZE * 1000000 - 1))

echo "add partitions"
# kernel partition's size in sectors (actually it's 1MB smaller due to
# the 2048 sectors start offset for alignment)
KPARTSIZE=$((16*1024*2))
parted build_tmp/usb.img mklabel msdos
parted -a none build_tmp/usb.img mkpart primary fat16 2048s ${KPARTSIZE}s
parted -a none build_tmp/usb.img mkpart primary ext2 $(($KPARTSIZE + 1))s $SIZE

mkdir -p build_tmp/usbstick/p1 build_tmp/usbstick/p2
sudo bash << EOF
# map the image so that we can mount see the partitions in the image
kpartx -v -a -p -usbstick- build_tmp/usb.img
# wait for the devices to be created
udevadm settle

# create the filesystems
mkdosfs   -v -n KERNEL  /dev/mapper/*-usbstick-1
mkfs.ext3 -v -L root-fs /dev/mapper/*-usbstick-2

# mount the partitions
mount -v /dev/mapper/*-usbstick-1 build_tmp/usbstick/p1
mount -v /dev/mapper/*-usbstick-2 build_tmp/usbstick/p2

# just check if the directory is here, is easier than reliably
# propagating TARGET into sudo...
if [ -d build_tmp/sparksystem ]; then
	# TARGET=spark
	echo "copying build_tmp/sparksystem/p1/"
	cp    build_tmp/sparksystem/p1/* build_tmp/usbstick/p1/
	echo "copying build_tmp/sparksystem/p2/"
	cp -a build_tmp/sparksystem/p2/* build_tmp/usbstick/p2/
else
	# copy kernel...
	echo "copying build_tmp/*Image.img"
	cp build_tmp/*Image.img build_tmp/usbstick/p1
	# ...and rootfs
	echo "copying build_tmp/install/."
	cp -a build_tmp/install/.  build_tmp/usbstick/p2
fi
# create /dev/console for first boot
# sudo mknod -m 644 build_tmp/usbstick/p2/dev/console c 5 1

# wait for potential udev stuff examining one of our mountpoints
udevadm settle
# unmount everything
umount build_tmp/usbstick/p*

# unbind the loop devices
kpartx -v -d -p -usbstick- build_tmp/usb.img
EOF

echo
echo "the usb boot image is now in build_tmp/usb.img"
echo
ls -l build_tmp/usb.img
echo

#STAMP=`date +%Y-%m-%d_%H-%M`
STAMP=$1
cp -v build_tmp/usb.img build_tmp/usb_$STAMP.img
