#!/bin/bash

echo "./footprint2.exp \$1 \$2 \$3" > exp_dd.sh
chmod +x exp_dd.sh

for i in {0..10}; do
	rbd rm images/ub$i.qcow2
	rbd import /mnt/cephfs/qcow2-snapshots/expes/disk/ub-18.04_50G.qcow2 images/ub$i.qcow2
done
#cp disk/snapshot-50 /tmp/ub_tmp0.qcow2

nodes_id=(186 214 201 204 206 222 187 243 228 242 210 229)
client_nodes=(node11 node0 node10 node11 node0 node10 node11 node0 node10 node11 node0)

nodes=()
for id in ${nodes_id[@]}; do
        nodes+=(amd$id.utah.cloudlab.us)
done

pid_arr=()
for i in $(seq 1 3 10); do
        pid_arr=()
        let sec="35*$i"
        echo "$i" >> dd_footprint
        #sleep $sec
        ssh -o StrictHostKeyChecking=no root@${client_nodes[1]} "/users/nivekiba/footprint2.exp useless rbd:images/ub$i.qcow2 6M" > /users/nivekiba/dd$i"0" &
        pidd=$!
        echo $pidd >> /tmp/order
        pid_arr+=($pidd)
        #ssh -i /root/id_rsa -o StrictHostKeyChecking=no -f root@${nodes[0]} "nohup /root/sar.sh &"

        for j in $(seq 1 $i); do
                echo "run $j"
                #./footprint_ssh.sh /mnt/cephfs/qcow2-snapshots/qemu-4.2-vanilla/build disk/ub_tmp$j.qcow2 6M &
                #./exp_dd.sh /mnt/cephfs/qcow2-snapshots/qemu-4.2-vanilla/build disk/ub_tmp$j.qcow2 6M > dd$i$j &
                ssh -o StrictHostKeyChecking=no root@${client_nodes[$j]} "/users/nivekiba/footprint2.exp useless rbd:images/ub$j.qcow2 6M" > /users/nivekiba/dd$i$j &
                pidd=$!
                echo $pidd >> /tmp/order
                pid_arr+=($pidd)
        done
        for node in ${nodes[@]}; do
                ssh -o StrictHostKeyChecking=no root@$node "touch /users/nivekiba/sar_res_$node-$i && chmod 0777 /users/nivekiba/sar_res_$node-$i"
                ssh -o StrictHostKeyChecking=no -fn \
                        root@$node \
                        "echo 'sar -n DEV -u -db 1 400 > /users/nivekiba/sar_res_$node-$i' > sar.sh && chmod +x ./sar.sh && nohup ./sar.sh &"
        done
        #ssh -i /root/id_rsa -o StrictHostKeyChecking=no -f root@${nodes[1]} "nohup /root/sar.sh &"

        #sleep $sec
        #./exp_dd.sh /mnt/cephfs/qcow2-snapshots/qemu-4.2-vanilla/build /tmp/ub_tmp0.qcow2 6M > dd$i &
        #main=$!
        wait ${pid_arr[@]}

        #ssh -i /root/id_rsa -o StrictHostKeyChecking=no -f root@${nodes[0]} "pkill -SIGINT sar; sleep 10; cp /root/sartest /root/sar0$i"
        #ssh -i /root/id_rsa -o StrictHostKeyChecking=no -f root@${nodes[1]} "pkill -SIGINT sar; sleep 10 ;cp /root/sartest /root/sar1$i"

        echo "arr ? wait ${pid_arr[@]}" >> /tmp/order
        #echo "wait $main" >> /tmp/order
        #wait $main

        sleep 100
        ./clear_ram.sh
	echo 3 > /proc/sys/vm/drop_caches
	cat /tmp/out.txt | awk '{print "ceph osd rm-"$3 " " $4}' | tr "_" "-" > /tmp/fichier
	source /tmp/fichier
	rm /tmp/out.txt
	rm /tmp/fichier

	./clear_ram.sh
	echo 3 > /proc/sys/vm/drop_caches
        for i in {0..10}; do
		rbd rm images/ub$i.qcow2
                rbd import /mnt/cephfs/qcow2-snapshots/expes/disk/ub-18.04_50G.qcow2 images/ub$i.qcow2
        done
	#python3 /users/nivekiba/balancer.py
	wait; sleep 4; while ceph status | grep -q "peering\|activating"; do sleep 2; done
done


mutt -s "End of experiment" kevinnguetchouang@gmail.com < /dev/null
