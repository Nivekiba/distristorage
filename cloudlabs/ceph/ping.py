import os
os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"]="python"

import etcd3

etcd = etcd3.client("10.10.1.1")

osds=[]

for i in range(1,10):
	osds+=["node"+str(i)]

import time
import socket
import numpy as np
from pythonping import ping

last=None

def process():
	global last
	latencies=[]
	for osd in osds:
		laa = ping(target=osd, count=2).rtt_avg_ms
		latencies+=[int(laa)]
	if last == None:
		#last = np.std(latencies)
		last = latencies
	else:
		#if abs(last-np.std(latencies)) <0.25:
		if last == latencies:
			return
		last = latencies
	etcd.put(socket.gethostname().split(".")[0], str(latencies))

while True:
	process()
	time.sleep(5)
