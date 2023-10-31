#!/bin/bash

sudo pip3 install pyjwt
sudo pip3 install python-dateutil

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

mon_host="node0-link-1"

echo $mon_host >> /tmp/lss
numeric_ip=`ping -q -W1 -c1 $mon_host | head -n1 | cut -d "(" -f2 | cut -d ")" -f1`
echo $numeric_ip >> /tmp/lss

# split from delimiter
host_name_mon=($(echo $mon_host | tr "." " "))

echo $host_name_mon >> /tmp/ls

cd /mydata/ceph/build

# start cluster
cat ~/.ssh/id_rsa.pub | sudo ssh -o StrictHostKeyChecking=no root@node0 tee -a /root/.ssh/authorized_keys
cat ~/.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no root@node0 tee -a /root/.ssh/authorized_keys

sudo ssh -o StrictHostKeyChecking=no node0 systemctl restart sshd
ssh -o StrictHostKeyChecking=no node0 systemctl restart sshd

timeout 60 sudo ../src/stop.sh
sudo rm out dev -rf
MON=3 OSD=2 MDS=1 MGR=1 RGW=1 NFS=1 timeout 120 sudo ../src/vstart.sh -n -d -i 10.10.1.1 --cephadm #-o "debug objecter = 30"

# end start

./bin/ceph orch host add $mon_host 
./bin/ceph orch host label add $mon_host mon

osd_nodes=${nodes_list[@]:1}



# cat ~/.ssh/id_rsa.pub | sudo ssh root@node1 tee -a /root/.ssh/authorized_keys
# cat ~/.ssh/id_rsa.pub | sudo ssh root@node1 tee -a /root/.ssh/authorized_keys
i=1
for node in $osd_nodes; do
	cat ~/.ssh/id_rsa.pub | sudo ssh node$i tee -a /root/.ssh/authorized_keys
	cat ~/.ssh/id_rsa.pub | ssh node$i tee -a /root/.ssh/authorized_keys

	sudo ssh -o StrictHostKeyChecking=no root@node$i systemctl restart sshd
	ssh -o StrictHostKeyChecking=no root@node$i systemctl restart sshd
        docker_ids=$(ssh -o StrictHostKeyChecking=no root@node$i "docker ps | grep ceph-osd | cut -f 1 -d\" \"")
        ssh -o StrictHostKeyChecking=no root@node$i "docker stop $docker_ids"
	ssh -o StrictHostKeyChecking=no root@node$i "hostname node$i-link-1 && sleep 5"
	ssh -o StrictHostKeyChecking=no root@node$i "sudo lvremove /dev/emulab/node0-bs --yes"
        ssh -o StrictHostKeyChecking=no root@node$i "vgremove emulab --yes"
        ssh -o StrictHostKeyChecking=no root@node$i "vgcreate emulab /dev/sdb"
        ssh -o StrictHostKeyChecking=no root@node$i "lvcreate -L 400G -n node0-bs emulab"

	sudo ./bin/ceph orch host add node$i-link-1
	sleep 10
        echo "osd=>"$host_name
        echo "osd=>"$host_name >> /tmp/ls
        sudo ./bin/ceph orch host label add node$i-link-1 osd
	echo "=================================================================================================================================="
	echo "=================================================================================================================================="
        sleep 5
	sudo ./bin/ceph orch daemon add osd node$i-link-1:emulab/node0-bs
	let i="i+1"
	if [[ $i -gt 9 ]]; then
		echo "Done, exiting"
		break
	fi
done


#sudo ./bin/ceph osd crush remove 0
#sudo ./bin/ceph osd stop 0
#sleep 5
#sudo ./bin/ceph osd purge 0

#sudo ./bin/ceph osd crush remove 1
#sudo ./bin/ceph osd stop 1
#sleep 5
#sudo ./bin/ceph osd purge 1

sudo ./bin/ceph -s
