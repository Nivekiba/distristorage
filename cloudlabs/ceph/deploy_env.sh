#!/bin/bash

nodes=(127 133 130 168 138 142 151 131 162 161 166 135)
admin=${nodes[0]}
nodes=${nodes[*]}

nodes_etc=(221 206 239)
prefix="amd"

pid_arr=()
if ! [ -z "$1" ]; then
	for node in $nodes; do
		echo $'\e[1;33m'$node$'\e[0m'
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us 'bash -s' < ./install_dep.sh &
		pidd=$!
		pid_arr+=($pidd)
	done
	wait ${pid_arr[@]}
	for node in $nodes; do
		echo $'\e[1;33m'$node$'\e[0m'
		#ssh -p 22 -o StrictHostKeyChecking=no nivekiba@amd$node.utah.cloudlab.us 'bash -s' < ./install_dep.sh
		scp -o StrictHostKeyChecking=no id_rsa* nivekiba@$prefix$node.utah.cloudlab.us:.ssh
		scp -o StrictHostKeyChecking=no grow-rootfs.sh nivekiba@$prefix$node.utah.cloudlab.us:
		scp -o StrictHostKeyChecking=no install_etc.sh etcd_serv.sh ping.py multi_run2.sh nivekiba@$prefix$node.utah.cloudlab.us:
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us "echo 'env RESIZEROOT=150 ./grow-rootfs.sh' > grow.sh && chmod +x ./grow.sh && chmod +x ./grow-rootfs.sh && sudo ./grow.sh"
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us "cat .ssh/id_rsa.pub >> .ssh/authorized_keys"
	done
fi

for node in $nodes_etc; do
	echo $'\e[1;33m'$node$'\e[0m'
	ssh -p 22 -o StrictHostKeyChecking=no nivekiba@$prefix$node.utah.cloudlab.us 'bash -s' < ./install_etc.sh &
	pidd=$!
	pid_arr+=($pidd)
done
wait ${pid_arr[@]}

scp -o StrictHostKeyChecking=no ./setup_cephadmin.sh nivekiba@$prefix$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./setup_cephfs.sh nivekiba@$prefix$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./multi_run.sh nivekiba@$prefix$admin.utah.cloudlab.us:

scp -o StrictHostKeyChecking=no ./add_latence.sh nivekiba@$prefix$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./rm_latence.sh nivekiba@$prefix$admin.utah.cloudlab.us:

ssh -o StrictHostKeyChecking=no -p 22 \
	 nivekiba@$prefix$admin.utah.cloudlab.us "sudo ./setup_cephadmin.sh $nodes && sudo ./setup_cephfs.sh $nodes"
