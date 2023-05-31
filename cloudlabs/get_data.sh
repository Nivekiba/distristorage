#!/bin/bash

nodes_id=(205 165 168 122 201 174 159 176 210 108)
nodes=()
for id in ${nodes_id[@]}; do
        nodes+=(amd$id.utah.cloudlab.us)
done

rm -rf ./data
mkdir -p ./data

#for node in ${nodes[@]}; do
#	ssh -o StrictHostKeyChecking=no nivekiba@$node "sudo chmod -R 0777 /root/sar_res_amd* && cp /root/sar_res_amd* /users/nivekiba && sudo chmod -R 0777 /users/nivekiba/*"
#	scp -o StrictHostKeyChecking=no nivekiba@$node:/users/nivekiba/sar_res_amd* ./data
#done

for node in ${nodes[@]}; do
       scp -o StrictHostKeyChecking=no nivekiba@$node:/users/nivekiba/sar_res_amd* ./data
       scp -o StrictHostKeyChecking=no nivekiba@$node:/users/nivekiba/sar_create* ./data
       scp -o StrictHostKeyChecking=no nivekiba@$node:/users/nivekiba/dd* ./data
done
