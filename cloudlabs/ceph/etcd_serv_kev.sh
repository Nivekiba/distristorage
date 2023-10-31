TOKEN=token-01
CLUSTER_STATE=new

etc_nodes=$@

NAMES=()
HOSTS=()

i=1
for node in ${etc_nodes[@]}; do
	echo $node
	NAMES+=(machine-$i)
	let i="i+1"
	tmp=`ping -q -W1 -c1 $node | head -n1 | cut -d "(" -f2 | cut -d ")" -f1`
	echo $tmp
	HOSTS+=($tmp)
	ssh $node -o StrictHostKeyChecking=no "sudo pip3 install pythonping numpy etcd3"
	scp -o StrictHostKeyChecking=no /mydata/ceph/build/keyring $node:/mydata/ceph/build/keyring
        scp -o StrictHostKeyChecking=no /mydata/ceph/build/ceph.conf $node:/mydata/ceph/build/ceph.conf
done

echo ${HOSTS[*]}
echo ${NAMES[*]}


#CLUSTER=${NAME_1}=http://${HOST_1}:2380,${NAME_2}=http://${HOST_2}:2380
CLUSTER=""

n=$#
let n="n-1"

for i in $(seq 0 $n); do
	CLUSTER+=${NAMES[$i]}"=http://"${HOSTS[$i]}":2380,"
done

echo $CLUSTER
exit

for i in $(seq 0 $n); do
	THIS_NAME=${NAMES[$i]}
	THIS_IP=${HOSTS[$i]}
	ssh $THIS_IP tmux new -d "etcd --data-dir=data.etcd --name ${THIS_NAME} \
          --initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
          --advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://${THIS_IP}:2379 \
          --initial-cluster ${CLUSTER} \
          --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}"
	echo "etcd --data-dir=data.etcd --name ${THIS_NAME} \
	  --initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
	  --advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://${THIS_IP}:2379 \
	  --initial-cluster ${CLUSTER} \
	  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}"
done

sleep 10
for i in $(seq 0 $n); do
	THIS_IP=${HOSTS[$i]}
	ssh $THIS_IP "sudo pip3 install etcd3 && PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python sudo  python3 /users/nivekiba/ping.py &" &
done
