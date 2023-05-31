#!/bin/bash

SNAPSHOTS=$1
QEMU_CMD_DIR=$2
SNAPSHOTS_DIR=$3
DISK_DIR=$4
disk_size=$5 # objecr in rbd


let megas="(${disk_size:0:-1}-39)*1024/$SNAPSHOTS"



if [ -z "$SNAPSHOTS" ]; then
	echo "\nCommand usage:\n\t ./gen_uniform_snapshots.sh NB_SNAPSHOTS PATH_TO_QEMU SNAPSHOTS_DIR DISK_DIR disk_size\n"
	exit
fi

SNAPSHOTS_DIR=`realpath $SNAPSHOTS_DIR`
DISK_DIR=`realpath $DISK_DIR`

for i in {1..10}; do
	rbd rm images/snap$i
done

sudo qemu-img create rbd:images/snap1 -b rbd:images/ub.qcow2 -f qcow2 -F qcow2
sudo ./write_data.exp $QEMU_CMD_DIR rbd:images/snap1 $megas
sudo ./write_data.exp $QEMU_CMD_DIR rbd:images/snap1 $megas

i=2
j=1

while true; do
	if [[ $i -gt $SNAPSHOTS ]]; then
		echo "Snapshots created"
		break
	fi

	sudo qemu-img create rbd:images/snap$i -b rbd:images/snap$j -f qcow2 -F qcow2
	sudo ./write_data.exp $QEMU_CMD_DIR rbd:images/snap$i $megas

	sudo ./clear_ram.sh
	sync
	
	let j="$i"
	let i="$i+1"
done

echo "End creation of snapshots"
