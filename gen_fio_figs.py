import os

import parse
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import csv

import glob
import os
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib.ticker import MaxNLocator


dirrs=[
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-snap20/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-1netdelay0.1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-snap20-1netdelay0.1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-1netdelay1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-snap20-1netdelay1/",

    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-ceph-fio/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-ceph-fio-snap20/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-ceph-fio-1netdelay0.1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-ceph-fio-snap20-1netdelay0.1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-ceph-fio-1netdelay1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-ceph-fio-snap20-1netdelay1/",

    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-snap/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-snap-b/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-mul/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-mul-b/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary2/",
]
datas = {}
for dir in dirrs:
    l_r = []
    l_w = []
    for i in range(1, 11, 3):
        with open(dir+"dd"+str(i)+"0") as fd:
            try:
                lines = fd.readlines()
                a,_,b = lines[-11:][:3]
                if "MiB/s" in b:
                    bw_r = parse.parse("bw={:g}MiB/s", b.split()[1])
                    l_r += [bw_r[0]*1000]
                else:
                    bw_r = parse.parse("bw={:g}KiB/s", b.split()[1])
                    l_r += [bw_r[0]]
            except:
                print("?")
                pass

    filename=dir.split("/")[-2].replace(".", "-")
    if "ro" in dir:
        filename += "-ro"
    datas[filename] = l_r

print(datas.keys())

add_latencies = [0, 0.1, 1]

keyss = ["data-ceph-fio-ro", "data-ceph-fio-1netdelay0-1-ro", "data-ceph-fio-1netdelay1-ro"]

for i, nw in enumerate([1, 4, 7, 10]):
    fig, ax = plt.subplots()
    y_values = []
    for keys in keyss:
        y_values += [datas[keys][i]]
    
    ax.bar(list(map(str, add_latencies)), y_values)

    ax.set_ylabel("Throughput(KiB/s)")
    ax.set_xlabel("Virtual latency added(ms)")
    ax.set_title(str(nw)+" workload(s)")

    plt.savefig("figs-throughput/throughput_ceph_with_"+str(nw)+"_workloads")
    plt.close(fig)

dts = {}
for dirr in dirrs:
    filn = dirr.split("/")[-2]
    for i in range(1, 11, 3):
        with open(dirr+"dd"+str(i)+str(i)) as fd:
            lines = fd.readlines()
            
            jobs = []
            for line in lines:
                if "Jobs" in line and "r=" not in line:
                    jobs = []
                if "Jobs" in line and "r=" in line:
                    h = line.split("r=")[1].split(",")[0]
                    if "MiB/s" in h:
                        t = parse.parse("{:g}MiB/s", h)
                        t = t[0]*1000
                    else:
                        t = parse.parse("{:g}KiB/s", h)
                        t = t[0]

                    jobs += [t]
            fig, ax = plt.subplots()
           
            ax.plot(jobs)
            dts[filn+"-"+str(i)] = jobs
            ax.set_xlabel("time(s)")
            
            plt.yticks(np.arange(0, max(jobs)+1, 1000))
            ax.set_ylabel("throughput(KiB/s")
            add = ""
            if "snap" in dirr: add = " - with snapshots"

            ax.set_title("Evolution of throughput during workload"+add)

            filename=dirr.split("/")[-2].replace(".", "-")
            plt.savefig("figs-throughput/during_"+filename+"-"+str(i))
            plt.close(fig)

import pandas as pd
import numpy as np

fig, ax = plt.subplots()

datass = {}
for i, nw in enumerate(range(1, 11, 3)):
    if nw not in datass:
        datass[nw] = {}
    datass[nw]["0ms"] = {
        "0 snap": datas["data-gluster-fio-ro"][i],
        "20 snap": datas["data-gluster-fio-snap20-ro"][i]
    }

    datass[nw]["0.1ms"] = {
        "0 snap": datas["data-gluster-fio-1netdelay0-1-ro"][i],
        "20 snap": datas["data-gluster-fio-snap20-1netdelay0-1-ro"][i]
    }

    datass[nw]["1ms"] = {
        "0 snap": datas["data-gluster-fio-1netdelay1-ro"][i],
        "20 snap": datas["data-gluster-fio-snap20-1netdelay1-ro"][i]
    }

import pandas as pd
fig, axes = plt.subplots(nrows=1, ncols=4, sharex=True, sharey=True)

for i, nw in enumerate(datass):
    df = pd.DataFrame(datass[nw])
    df.plot(kind="bar", ax=axes[i])
    axes[i].set_xlabel(str(nw)+" workload(s)")
    axes[i].tick_params(axis='x', rotation=45)

fig.supylabel("Throughput (Kb/s)")
plt.savefig("figs-throughput/global_gluster", bbox_inches="tight")
#plt.show()


for i in range(1, 11, 3):
    fig, ax = plt.subplots()
    ax.plot(dts["data-vary-mul-"+str(i)], label="without balancer")
    ax.plot(dts["data-vary-mul-b-"+str(i)], label="with balancer")
    ax.set_title("Evolution of throughput during workload("+str(i)+" workloads)")
    ax.set_xlabel("time(s)")
    ax.legend()

    plt.yticks(np.arange(0, max(dts["data-vary-mul-"+str(i)])+1, 1000))
    ax.set_ylabel("throughput(KiB/s")

    plt.savefig("figs-throughput/during_data-vary-mul_and_b-"+str(10-i+1))
    print(i, sum(dts["data-vary-mul-"+str(i)][500:700])/200)
    print(i, sum(dts["data-vary-mul-b-"+str(i)][500:700])/200)
    plt.close(fig)
    #plt.show()