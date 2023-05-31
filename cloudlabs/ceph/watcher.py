kkimport os
os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"]="python"

import etcd3
import numpy as np

etcd = etcd3.client("10.10.1.1")

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
	n = []

import time
while True:
	time.sleep(5)

etcd.cancel_watch(watch_id)
