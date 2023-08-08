#!/bin/bash

echo "./footprint.exp \$1 \$2 \$3" >> exp_dd.sh
chmod +x exp_dd.sh

prefix="amd"

for i in {0..10}; do
        cp disk/ub-18.04_50G.qcow2 disk/ub_tmp$i.qcow2
done
#cp disk/snapshot-50 /tmp/ub_tmp0.qcow2

nodes_id=(221 213 234 228 220 214 208 232 205 211 206 239)
nodes=()
for id in ${nodes_id[@]}; do
        nodes+=($prefix$id.utah.cloudlab.us)
done

pid_arr=()
for i in $(seq 1 3 10); do
        pid_arr=()
        let sec="35*$i"
        echo "$i" >> dd_footprint
        #sleep $sec
        ./exp_dd.sh /mnt/cephfs/qcow2-snapshots/qemu-4.2-vanilla/build disk/ub_tmp0.qcow2 6M > /users/nivekiba/dd$i"0" &
        pidd=$!
        echo $pidd >> /tmp/order
        pid_arr+=($pidd)
        #ssh -i /root/id_rsa -o StrictHostKeyChecking=no -f root@${nodes[0]} "nohup /root/sar.sh &"

        for j in $(seq 1 $i); do
                echo "run $j"
                #./footprint_ssh.sh /mnt/cephfs/qcow2-snapshots/qemu-4.2-vanilla/build disk/ub_tmp$j.qcow2 6M &
                #./exp_dd.sh /mnt/cephfs/qcow2-snapshots/qemu-4.2-vanilla/build disk/ub_tmp$j.qcow2 6M > dd$i$j &
                ./exp_dd.sh /mnt/cephfs/qcow2-snapshots/qemu-4.2-vanilla/build disk/ub_tmp$j.qcow2 6M > /users/nivekiba/dd$i$j &
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

        rm disk/ub_tmp*
	./clear_ram.sh
        for i in {0..10}; do
                cp disk/ub-18.04_50G.qcow2 disk/ub_tmp$i.qcow2
        done
done


mutt -s "End of experiment" kevinnguetchouang@gmail.com < /dev/null
