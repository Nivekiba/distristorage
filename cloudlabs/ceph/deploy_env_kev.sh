#!/bin/bash

nodes=(201 182 129 141 199 148 162 154 203 159 151 160)
admin=${nodes[0]}
nodes=${nodes[*]}

prefix="amd"

pid_arr=()
ii=0
if ! [ -z "$1" ]; then
	for node in $nodes; do
		echo $'\e[1;33m'$node$'\e[0m'
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us 'bash -s' < ./install_dep_kev.sh &
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us "sudo hostname node$ii-link-1"
		let ii="ii+1"
		pidd=$!
		pid_arr+=($pidd)
	done
	wait ${pid_arr[@]}
        pid_arr=()
        for node in $nodes; do
                echo $'\e[1;33m'$node$'\e[0m'
                ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us 'bash -s' < ./install_etc.sh &
                pidd=$!
                pid_arr+=($pidd)
        done
        wait ${pid_arr[@]}
	for node in $nodes; do
		echo $'\e[1;33m'$node$'\e[0m'
		#ssh -p 22 -o StrictHostKeyChecking=no nivekiba@amd$node.utah.cloudlab.us 'bash -s' < ./install_dep.sh
		scp -o StrictHostKeyChecking=no id_rsa* nivekiba@$prefix$node.utah.cloudlab.us:.ssh
		scp -o StrictHostKeyChecking=no grow-rootfs.sh ./add_delay.sh ./rm_delay.sh nivekiba@$prefix$node.utah.cloudlab.us:
		scp -o StrictHostKeyChecking=no footprint_rbd.exp nivekiba@$prefix$node.utah.cloudlab.us:~/footprint2.exp
		scp -o StrictHostKeyChecking=no ../../ceph-r/install-deps.sh install_etc.sh etcd_serv_kev.sh ping.py multi_run2.sh multi_client_kev.sh nivekiba@$prefix$node.utah.cloudlab.us:
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us "echo 'env RESIZEROOT=150 ./grow-rootfs.sh' > grow.sh && chmod +x ./grow.sh && chmod +x ./grow-rootfs.sh && sudo ./grow.sh"
		#ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us "cat .ssh/id_rsa.pub >> .ssh/authorized_keys"
	done
fi

scp -o StrictHostKeyChecking=no ./setup_cephadmin_kev.sh nivekiba@$prefix$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./setup_cephfs.sh nivekiba@$prefix$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./multi_run.sh nivekiba@$prefix$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./multi_client_kev.sh nivekiba@$prefix$admin.utah.cloudlab.us:

scp -o StrictHostKeyChecking=no ./add_latence.sh nivekiba@$prefix$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./rm_latence.sh nivekiba@$prefix$admin.utah.cloudlab.us:

ssh -o StrictHostKeyChecking=no -p 22 \
	 nivekiba@$prefix$admin.utah.cloudlab.us "#sudo ./etcd_serv_kev.sh node0 node10 node11; sudo ./setup_cephadmin_kev.sh $nodes && sudo ./setup_cephfs.sht $nodes"
