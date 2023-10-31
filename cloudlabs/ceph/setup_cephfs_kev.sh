lls #!/bin/bash

nodes_lists=$@
nodes_list=()
echo $nodes_lists >> /tmp/test
for host in $nodes_lists; do
        echo $host >> inventory.ini
        nodes_list+=($host)
done

cd /mydata/ceph/build

sudo ./bin/ceph osd pool create cephfs-data 32
sudo ./bin/ceph osd pool create cephfs-metadata 32

sudo ./bin/ceph osd pool set cephfs-data size 3
sudo ./bin/ceph osd pool set cephfs-metadata size 3

sudo ./bin/ceph-authtool -p ./keyring | sudo tee admin.key

echo "
service_type: mds
service_id: fs_name
placement:
  count: 3
" > mds.yaml

sudo ./bin/ceph orch apply -i mds.yaml

sudo ./bin/ceph fs new cephfs cephfs-metadata cephfs-data --force
sudo ./bin/ceph osd pool set cephfs-data allow_ec_overwrites true

sudo ./bin/ceph auth get-or-create client.1 mon 'allow r' mds 'allow rw' osd 'allow rw pool=data'

sudo mkdir -p /mnt/cephfs
#mds_server=${nodes_list[0]}
mds_server="node0-link-1"
sleep 30
sudo ./bin/mount.ceph $mds_server:6789:/ /mnt/cephfs/ -o name=admin,secretfile=admin.key
echo "mount -t ceph $mds_server:6789:/ /mnt/cephfs/ -o name=admin,secretfile=admin.key" > /tmp/mount


cd /mydata

sudo git clone https://github.com/Nivekiba/qcow2-snapshots
cd qcow2-snapshots/qemu-4.2-vanilla
mkdir build
cd build
sudo ../configure --target-list=x86_64-softmmu --enable-debug-info --enable-debug --enable-debug-tcg
sudo make -j

cd /mydata/qcow2-snapshots/expes

sudo chmod 600 ./keys/id_rsa

sudo ./create-vm.sh 50G
echo "./gen_uniform_snapshot.sh 50 ../qemu-4.2-vanilla/build ./disk ./disk 50G" >> gen.sh
sudo chmod +x ./gen.sh

cp ~/multi_run.sh .

sudo chmod +x ./multi_run.sh
