#!/bin/bash

nodes_lists=$@
nodes_list=()
echo $nodes_lists >> /tmp/test
for host in $nodes_lists; do
        echo $host >> inventory.ini
        nodes_list+=($host)
done

ceph osd pool create cephfs-data 32
ceph osd pool create cephfs-metadata 32

ceph-authtool -p /etc/ceph/ceph.client.admin.keyring > admin.key

echo "
service_type: mds
service_id: fs_name
placement:
  count: 3
" > mds.yaml

ceph orch apply -i mds.yaml

ceph fs new cephfs cephfs-metadata cephfs-data --force
ceph osd pool set cephfs-data allow_ec_overwrites true

ceph auth get-or-create client.1 mon 'allow r' mds 'allow rw' osd 'allow rw pool=data'

mkdir -p /mnt/cephfs
#mds_server=${nodes_list[0]}
mds_server="node0-link-1"
sleep 30
mount -t ceph $mds_server:6789:/ /mnt/cephfs/ -o name=admin,secretfile=admin.key
echo "mount -t ceph $mds_server:6789:/ /mnt/cephfs/ -o name=admin,secretfile=admin.key" > /tmp/mount


cd /mnt/cephfs

git clone https://github.com/Nivekiba/qcow2-snapshots
cd qcow2-snapshots/qemu-4.2-vanilla
mkdir build
cd build
../configure --target-list=x86_64-softmmu --enable-debug-info --enable-debug --enable-debug-tcg
make -j

cd /mnt/cephfs/qcow2-snapshots/expes

chmod 600 ./keys/id_rsa

./create-vm.sh 50G
echo "./gen_uniform_snapshot.sh 50 ../qemu-4.2-vanilla/build ./disk ./disk 50G" >> gen.sh
chmod +x ./gen.sh

cp ~/multi_run.sh .

chmod +x ./multi_run.sh
