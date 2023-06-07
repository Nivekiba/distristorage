import json
import rados
import numpy as np

import os
os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"]="python"

import etcd3
import numpy as np

etcd = etcd3.client("node0")

n=[]

def watch_callback(event):
    global n
    ty = type(event.events[0]) # this string can help retrieve the type of op (put, delete) not sure i need it now
    print(event.events[0])
    n+=[event.events[0].value.decode()]
    if len(n) == 3: catchup()

watch_id = etcd.add_watch_prefix_callback("node", watch_callback)

def catchup():
    global n
    print("get the catchup", n)
    values = []
    for e in n: values += [eval(e)]
    values = np.mean(values, axis=0)
    print(values)
    process(values)
    n = []

cluster = rados.Rados(conffile="/etc/ceph/ceph.conf")

cluster.connect()

last = None

def process(latenc):
    global last

    cmd = json.dumps({"prefix": "health", "format": "json"})
    res = cluster.mon_command(cmd, b'')
    if "HEALTH_OK" in res[1].decode():
        #print("health ok, we can do this")
        j=0
    else:
        #print("health not ok, wait system stabilizes")
        cmd = json.dumps({"prefix": "crash archive-all", "format": "json"})
        res = cluster.mon_command(cmd, b'')
        return

    cmd = json.dumps({"prefix": "osd perf", "format": "json"})

    res = cluster.mgr_command(cmd, b'')

    result = json.loads(res[1].decode())

    # ceph.commit_latency_ms: Time in milliseconds to commit an operation
    # ceph.apply_latency_ms: Time in milliseconds to sync to disk

    num_osds = len(result["osdstats"]["osd_perf_infos"])
    affs = [1.0]*num_osds
    latencies = latenc

    # Nothing to do if all latencies are the same
    if len(set(latencies)) == 1:
        print("nothing to do")
    else:
        sum_last = sum(latencies)
        for i, lat in enumerate(latencies):
            affs[i] = 1 - lat/sum_last

    for i, lat in enumerate(affs):
        if lat == max(affs):
            affs[i] = 1.0
    
    if last == None:
        last = np.std(latencies)
    else:
        if abs(last-np.std(latencies)) <0.25:
            return
        else:
            last = np.std(latencies)

    for i, aff in enumerate(affs):
        # ceph osd primary-affinity osd.<id> 0
        #aff = 1 # fix the affinity to 1, seems aff < 1 crush the system (don't know why)
        cmd = json.dumps({"prefix": "osd primary-affinity", "id":i,  "weight": aff, "format": "json"})
        res = cluster.mon_command(cmd, b'')
        print(res)

    cmd = json.dumps({"prefix": "osd getmap", "format":"json"})
    i, buf, err = cluster.mon_command(cmd, b'')
    f = open("/tmp/om", "wb")
    f.write(buf)
    f.close()
    # ./bin/ceph osd getmap -o om
    print(affs)

    import os

    os.system("/mydata/ceph/build/bin/osdmaptool /tmp/om --upmap /tmp/out.txt")
    os.system("/mydata/ceph/build/bin/osdmaptool /tmp/om --read /tmp/out.txt --read-pool cephfs-data")

    # with open("/tmp/out.txt", "r") as f:
    #     lines = f.readlines()
    #     for line in lines:
    #         os.system(line)
    
    os.system("python3 /users/nivekiba/test.py")

    #os.system("rm /tmp/out.txt /tmp/om")

import time

while True:
    time.sleep(5)
