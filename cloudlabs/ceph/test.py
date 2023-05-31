import json
import rados
from pythonping import ping
import numpy as np

cluster = rados.Rados(conffile="/etc/ceph/ceph.conf")

cluster.connect()

cmd = json.dumps({"prefix": "pg ls-by-pool", "poolstr": "images", "format": "json"})

res = cluster.mon_command(cmd, b'')

result = json.loads(res[1].decode())

dic={}
with open("/tmp/out.txt", "r") as f:
	lines = f.readlines()
	for l in lines:
		_, _, _,pg, osd = l.split()
		dic[pg] = int(osd)

import os
print(dic)
for a in result["pg_stats"]:
	#print(a["pgid"], a["up"])
	if a["pgid"] in dic.keys():
		print(a["pgid"], a["up"])
		a["up"].remove(dic[a["pgid"]])
		a["up"].insert(0, dic[a["pgid"]])
		print(a["up"])
		s = "ceph osd pg-upmap "+a["pgid"]+" "+" ".join(map(str, a["up"]))
		os.system(s)
