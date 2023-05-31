#!/bin/bash

#sudo su
nodes_lists=$@
nodes_list=()
echo $nodes_lists >> /tmp/test
for host in $nodes_lists; do
        echo $host >> inventory.ini
        nodes_list+=(amd$host.utah.cloudlab.us)
done


other_peers=${nodes_list[@]:1}
#peer1=${nodes_list[0]}
peer1="node0-link-1"
peer2="node1-link-1"

gv0_str=""
echo $nodes_lists
i=0
for node in ${nodes_lists[@]}; do
	echo $node
        gluster peer probe node$i-link-1 #amd$node.utah.cloudlab.us
	ssh -o StrictHostKeyChecking=no amd$node.utah.cloudlab.us "sudo service glusterd restart; sudo rm -rf /mnt/*; umount /mnt; sudo mkdir -p /mydata/gv0"
        gv0_str+=node$i-link-1":/mydata/gv0 "
	let i="i+1"
done

to_rm="node0-link-1:/mydata/gv0"
gv0_str=${gv0_str#$to_rm}
#gluster volume create gv0 replica 3 $gv0_str force
echo $gv0_str > test
yes | gluster volume stop gv0
yes | gluster volume delete gv0
sleep 20
#gluster volume create gv0 $gv0_str

gluster volume create gv0 replica 3 $gv0_str

gluster volume set gv0 cluster.nufa on
gluster volume set gv0 cluster.read-hash-mode 5

gluster volume start gv0

mount -t glusterfs $peer1:/gv0 /mnt

cd /mnt

git clone https://github.com/Nivekiba/qcow2-snapshots
cd qcow2-snapshots/qemu-4.2-vanilla
mkdir build
cd build
../configure --target-list=x86_64-softmmu --enable-debug-info --enable-debug --enable-debug-tcg
make -j

cd /mnt/qcow2-snapshots/expes

chmod 600 ./keys/id_rsa

./create-vm.sh 20G
mv disk/ub-18.04_20G.qcow2 disk/ub-18.04_50G.qcow2

echo "./gen_uniform_snapshot.sh 50 ../qemu-4.2-vanilla/build ./disk ./disk 50G" >> gen.sh
chmod +x ./gen.sh

cp ~/multi_run.sh .
cp /users/nivekiba/multi_run.sh .

# clone git repo on all nodes
for node in $nodes_lists; do
        cd /root
        ssh -o StrictHostKeyChecking=no amd$node.utah.cloudlab.us "sudo mount -t glusterfs $peer1:/gv0 /mnt"
done


chmod +x ./multi_run.sh

# nohup ./multi_run.sh &
