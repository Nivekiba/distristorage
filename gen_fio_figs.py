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
# import scienceplots
# plt.style.use(['science', 'ieee'])

without=[11, 10, 7.5, 5.5]
withs = [11, 11, 10, 7.7]
with2 = [10, 11, 11.3, 7.3]
x=np.arange(4)

ax = plt.subplot(111)
ax.set_xlabel("Number of parallel workloads")
ax.set_ylabel("Throughput(MiB/s)")
ax.bar(x-0.2, without, width=0.2, align='center', label="Ceph")
ax.bar(x, withs, width=0.2, align='center', label="Ceph-UDA (alg 1)")
ax.bar(x+0.2, with2, width=0.2, align='center', label="Ceph-UDA (alg 2)")
plt.xticks(range(4), [1, 4, 7, 10])
ax.legend()
plt.savefig("figs-throughput/summary")

without_rocks1 = [1800, 1300, 895, 632]
without_rocks2 = [1460, 1470, 909, 676]
with_rocks1 = [1760, 1340, 972, 750]
with_rocks2 = [1680, 1341, 1021, 808]
plt.close()

ax = plt.subplot(111)
ax.set_xlabel("Number of parallel workloads")
ax.set_ylabel("Throughput(Op/s)")
ax.bar(x-0.2, without_rocks1, width=0.2, align='center', label="Ceph")
ax.bar(x, with_rocks1, width=0.2, align='center', label="Ceph-UDA (alg 1)")
ax.bar(x+0.2, with_rocks2, width=0.2, align='center', label="Ceph-UDA (alg 2)")
plt.xticks(range(4), [1, 4, 7, 10])
ax.legend()
plt.savefig("figs-throughput/summary-ceph")

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

    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-balance/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-balance-bal/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-tmp/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-tmp2/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-nobal/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-bal/",

    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-tmp-algo2/",
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
            ax.set_ylabel("throughput(KiB/s)")
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
    nobal_prefix = "data-vary-mul-"
    bal_prefix = "data-vary-mul-b-"
    #bal_prefix = "data-tmp2-"
    #nobal_prefix = "data-tmp-"
    ax.plot(dts[nobal_prefix+str(i)][::2], label="without balancer")
    ax.plot(dts[bal_prefix+str(i)][::2], label="with balancer")
    ax.set_title("Evolution of throughput during workload("+str(11-i)+" workloads)")
    ax.set_xlabel("time(s)")
    ax.legend()

    plt.yticks(np.arange(0, max(dts["data-vary-mul-"+str(i)])+1, 1000))
    ax.set_ylabel("Throughput(KiB/s)")

    plt.savefig("figs-throughput/during_data-vary-mul_and_b-"+str(10-i+1))
    print(i, sum(dts[nobal_prefix+str(i)][500:700])/200)
    print(i, sum(dts[bal_prefix+str(i)][500:700])/200)
    plt.close(fig)
    #plt.show()

# previous for loop but in a single figure
fig, axes = plt.subplots(nrows=4, ncols=1, sharex=True, sharey=True, figsize=(5, 8))
j=-1
for i in range(1, 11, 3):
    j+=1
    nobal_prefix = "data-vary-mul-"
    bal_prefix = "data-vary-mul-b-"
    #bal_prefix = "data-tmp2-"
    #nobal_prefix = "data-tmp-"
    axes[j].plot(dts[nobal_prefix+str(i)][::2], label="without balancer")
    axes[j].plot(dts[bal_prefix+str(i)][::2], label="balancer (algo 1)")

    axes[j].plot(dts["data-tmp-algo2-"+str(11-i)], label="balancer (algo 2)")

    axes[j].set_title(str(11-i)+" workload(s)")
    axes[j].get_yaxis().set_major_formatter(
    ticker.FuncFormatter(lambda x, p: str(int(x)/1000) ))
    
    #axes[j].legend()

    plt.yticks(np.arange(0, max(dts[nobal_prefix+str(i)])+1, 2000))

fig.supxlabel("Time(s)")
fig.supylabel("Throughput(MiB/s)")
import matplotlib as mpl
#fig.text(0.5, 0.04, '', va='center', ha='center', fontsize=mpl.rcParams['axes.labelsize'])
#fig.text(0.04, 0.5, 'Throuput(MB/s)', va='center', ha='center', rotation='vertical', fontsize=mpl.rcParams['axes.labelsize'])
plt.legend()
fig.tight_layout()
plt.savefig("figs-throughput/during_data-vary-mul_and_b_summary")
plt.close(fig)
    #plt.show()