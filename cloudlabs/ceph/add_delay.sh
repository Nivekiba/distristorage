src=$1


tc qdisc add dev ens1f0 root handle 1: prio
tc qdisc add dev ens1f0 parent 1:3 handle 30: netem delay 0.5ms
tc filter add dev ens1f0 protocol ip parent 1:0 prio 3 u32 \
   match ip dst $src flowid 1:3
