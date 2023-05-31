#!/bin/bash

nodes=(205 165 168 122 201 174 159 176 210 108)
admin=${nodes[0]}
nodes=${nodes[*]}

if ! [ -z "$1" ]; then
	for node in $nodes; do
		echo $'\e[1;33m'$node$'\e[0m'
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@amd$node.utah.cloudlab.us 'bash -s' < ./install_dep.sh
		scp -o StrictHostKeyChecking=no id_rsa* nivekiba@amd$node.utah.cloudlab.us:.ssh
		scp -o StrictHostKeyChecking=no grow-rootfs.sh nivekiba@amd$node.utah.cloudlab.us:
		ssh -p 22 -o StrictHostKeyChecking=no nivekiba@amd$node.utah.cloudlab.us "echo 'env RESIZEROOT=60 ./grow-rootfs.sh' > grow.sh && chmod +x ./grow.sh && chmod +x ./grow-rootfs.sh && sudo ./grow.sh"
	done
fi

scp -o StrictHostKeyChecking=no ./setup_gluster.sh nivekiba@amd$admin.utah.cloudlab.us:
scp -o StrictHostKeyChecking=no ./multi_run.sh nivekiba@amd$admin.utah.cloudlab.us:

ssh -o StrictHostKeyChecking=no -p 22 \
	 nivekiba@amd$admin.utah.cloudlab.us "sudo ./setup_gluster.sh $nodes"
