#!/bin/bash

node_id=$1

echo $node_id

ssh -o StrictHostKeyChecking=no root@node$node_id "tc qdisc del dev ens1f0np0 root"
