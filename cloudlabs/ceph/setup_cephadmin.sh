#!/bin/bash

#sudo wget -q https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm -P /usr/bin/
sudo wget -q https://github.com/ceph/ceph/raw/reef/src/cephadm/cephadm.py -P /usr/bin/
sudo ln -s /usr/bin/cephadm.py /usr/bin/cephadm
sudo chmod +x /usr/bin/cephadm

git clone https://github.com/ceph/cephadm-ansible

cd cephadm-ansible

nodes_lists=$@
nodes_list=()
echo "" > inventory.ini

i=0
echo $nodes_lists >> /tmp/test
for host in $nodes_lists; do
        echo node$i-link-1 >> inventory.ini
        nodes_list+=($host)
	let i="i+1"
done

#mon_host=${nodes_list[0]}
hostname node0-link-1
mon_host="node0-link-1"
echo "" >> inventory.ini
echo "[admin]" >> inventory.ini
echo "$mon_host" >> inventory.ini

#sed -i 's/ssh_args = -o ControlMaster=auto -o ControlPersist=600s/ssh_args = -o ControlMaster=auto -o ControlPersist=600s -i \/root\/id_rsa/g' ansible.cfg
ansible-playbook -i inventory.ini cephadm-preflight.yml --extra-vars "ceph_release=reef"

echo $mon_host >> /tmp/lss
numeric_ip=`ping -q -W1 -c1 $mon_host | head -n1 | cut -d "(" -f2 | cut -d ")" -f1`
echo $numeric_ip >> /tmp/lss
cephadm bootstrap --mon-ip $numeric_ip

cd ..

# split from delimiter
host_name_mon=($(echo $mon_host | tr "." " "))

echo $host_name_mon >> /tmp/ls
ceph config set mon mon_data_avail_warn 9
ceph orch upgrade start --ceph-version 17.2.0
ceph osd set-require-min-compat-client reef
ceph config set mon_osd_initial_require_min_compat_client reef --force

ceph orch host label add $mon_host mon

osd_nodes=${nodes_list[@]:1}

i=1
for node in $osd_nodes; do
        sleep 5
        host_name="node$i-link-1" #($(echo $node | tr "." " "))
        ssh-copy-id -f -i /etc/ceph/ceph.pub root@$host_name -o StrictHostKeyChecking=no
        ssh root@$host_name "hostname node$i-link-1"
	ssh root@$host_name "hostname node$i-link-1"
	sleep 20
	ssh root@$host_name "umount /mydata"
	ssh root@$host_name "lvremove /dev/emulab/node0-bs --yes"
        ssh root@$host_name "vgremove emulab --yes"
	ssh root@$host_name "lvremove /dev/emulab/node$i-bs --yes"
	ssh root@$host_name "vgcreate emulab /dev/sdb"
	ssh root@$host_name "lvcreate -L 400G -n node0-bs emulab"
	ceph orch host add $host_name
	sleep 20
        echo "osd=>"$host_name
        echo "osd=>"$host_name >> /tmp/ls
        ceph orch host label add $host_name osd
	echo "=================================================================================================================================="
	echo "=================================================================================================================================="
        sleep 20
	ceph orch daemon add osd $host_name:emulab/node0-bs
	let i="i+1"
	if [[ $i -gt 9 ]]; then
		echo "Done, exiting"
		break
	fi
done

ceph -s
