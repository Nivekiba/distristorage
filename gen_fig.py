import parse
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import csv
import parse

import glob
import os
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib.ticker import MaxNLocator
import scienceplots
#plt.style.use(['science', 'ieee'])
mpl.rcParams.update({'font.size': 14})

dirrs=[
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-rocks-read-5/",
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-rocks/",
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-rocks2/",
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-nufa-fio/",
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-snap20/",
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-fio-snap20/",
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-fio-snap20-2netdelay5/",
    # "/home/nivek/Workspace/distristorage/cloudlabs/data-gluster-fio-snap20-1netdelay5-v2/",

    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-ceph-rep3-snap20-1netdelay5/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-ceph-rep3/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-ceph-rocks/",

    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-snap20/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-1netdelay1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ro/data-gluster-fio-snap20-1netdelay1/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-bal/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-nobal/",

    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-tmp/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/data-tmp2/",
]
remove_times = [
    # 250,
    # 250,
    # 250,
    # 100,
    # 100,
    # 100,
    # 100,
    # 10,

    100,
    100,
    200,

    100,
    100,
    100,
    100,
    100,
    100,

    100,
    100
]

disk_interfaces = [
    # "dev8-16",
    # "dev8-16",
    # "dev8-16",
    # "dev8-0",
    # "dev8-16",
    # "dev8-16",
    # "dev8-16",
    # "dev8-16",

    "dev8-0",
    "dev8-16",
    "dev8-0",

    "dev8-16",
    "dev8-16",
    "dev8-16",
    "dev8-16",
    "dev8-16",
    "dev8-16",

    "dev8-16",
    "dev8-16"
]

def is_lastsubstr(str, substr):
    if substr not in str:
        return False
    return str.index(substr) + len(substr) == len(str)

for dirr, remove_time, disk_int in zip(dirrs, remove_times, disk_interfaces):
    datas={}
    for f in os.listdir(dirr):
        try:
            ind, nwork =parse.parse("sar_res_amd{:d}.utah.cloudlab.us-{:d}", f)
        except:
            continue
        datas[str(ind)+"-"+str(nwork)] = {"network":[], "disk":[], "cpu":[]}
        with open(dirr+f, "r") as fd:
            lines = fd.readlines()
            for line in lines:
                if "ens1f0" in line:
                    #h = float(line.split()[-1])
                    h = float(line.split()[-5])+float(line.split()[-6])
                    datas[str(ind)+"-"+str(nwork)]["network"] += [h]
                if "all" in line:
                    # 2 => application level
                    # 4 => system level
                    h = float(line.split()[4])+float(line.split()[2])
                    datas[str(ind)+"-"+str(nwork)]["cpu"] += [h]
                if disk_int in line: # try with dev8-16 if it's now working with dev8-0
                    h = float(line.split()[-1]) ## real column for disk usage
                    #h = float(line.split()[-2]) ## column for queue length
                    datas[str(ind)+"-"+str(nwork)]["disk"] += [h]

    # end generation of all datas

    for procs in range(1, 11):
        fig, ax = plt.subplots()
        lines= []
        tmps=[]
        j=-1
        for k in datas:
            if is_lastsubstr(k, "-"+str(procs)):
                j+=1
                lab = k
                t = datas[k]["disk"][:]
                del t[-1]
                del t[:150]
                
                tmp = []
                for i in range(len(t)):
                    if t[i] > 0.5: tmp += [t[i]]
                #l = ax.plot(t, label=lab+" "+str(np.mean(tmp))[:4])
                add_percentage = str(np.mean(tmp))[:4]+"%" if not np.isnan(np.mean(tmp)) else ""
                l = ax.plot(t, label="node"+str(j)+" "+add_percentage)
                if not(np.isnan(np.mean(tmp))):
                    tmps+=[np.mean(tmp)]
                print(lab, np.mean(tmp))
                lines.append(l[0])
                
        leg = ax.legend()

        lined = {}  # Will map legend lines to original lines.
        for legline, origline in zip(leg.get_lines(), lines):
            legline.set_picker(True)  # Enable picking on the legend line.
            legline.set_pickradius(2)
            lined[legline] = origline

        def on_pick(event):
            # On the pick event, find the original line corresponding to the legend
            # proxy line, and toggle its visibility.
            legline = event.artist
            origline = lined[legline]
            visible = not origline.get_visible()
            origline.set_visible(visible)
            # Change the alpha on the line in the legend so we can see what lines
            # have been toggled.
            legline.set_alpha(1.0 if visible else 0.2)
            fig.canvas.draw()

        fig.canvas.mpl_connect('pick_event', on_pick)

        ax.set_ylabel("disk utilization (% of disk throughput used)")
        ax.set_xlabel("time (s)")
        #ax.set_title("mean: "+str(np.mean(tmps))+"\nstd: "+str(np.std(tmps)))
        os.system("mkdir -p figs/"+dirr.split("/")[-2])
        plt.savefig("figs/"+dirr.split("/")[-2]+"/"+str(procs))
        #plt.show()
    
    # network graphs
    for procs in range(1, 11):
        fig, ax = plt.subplots()
        lines= []
        tmps=[]
        j=-1
        for k in datas:
            if is_lastsubstr(k, "-"+str(procs)):
                j+=1
                lab = k
                t = datas[k]["network"][:]
                del t[-1]
                del t[:150]
                
                tmp = []
                for i in range(len(t)):
                    if t[i] > 0.: tmp += [t[i]]
                #l = ax.plot(t, label=lab+" "+str(np.mean(tmp))[:4])
                l = ax.plot(t, label="node"+str(j)+" "+str(np.mean(tmp))[:4])
                if not(np.isnan(np.mean(tmp))):
                    tmps+=[np.mean(tmp)]
                print(lab, np.mean(tmp))
                lines.append(l[0])
                
        leg = ax.legend()

        lined = {}  # Will map legend lines to original lines.
        for legline, origline in zip(leg.get_lines(), lines):
            legline.set_picker(True)  # Enable picking on the legend line.
            legline.set_pickradius(2)
            lined[legline] = origline

        def on_pick(event):
            # On the pick event, find the original line corresponding to the legend
            # proxy line, and toggle its visibility.
            legline = event.artist
            origline = lined[legline]
            visible = not origline.get_visible()
            origline.set_visible(visible)
            # Change the alpha on the line in the legend so we can see what lines
            # have been toggled.
            legline.set_alpha(1.0 if visible else 0.2)
            fig.canvas.draw()

        fig.canvas.mpl_connect('pick_event', on_pick)

        ax.set_ylabel("network utilization(bandwidth utilization)")
        ax.set_xlabel("time (s)")
        if len(tmps) > 0:
            for i in range(2): tmps.remove(max(tmps))
            tmps.remove(min(tmps))
        ax.set_title("mean: "+str(np.mean(tmps))+"\nstd: "+str(np.std(tmps)))
        os.system("mkdir -p figs-network/"+dirr.split("/")[-2])
        plt.savefig("figs-network/"+dirr.split("/")[-2]+"/"+str(procs))
        #plt.show()

    # cpu graphs
    for procs in range(1, 11):
        fig, ax = plt.subplots()
        lines= []
        tmps=[]
        j=-1
        for k in datas:
            if is_lastsubstr(k, "-"+str(procs)):
                j+=1
                lab = k
                t = datas[k]["cpu"][:]
                del t[-1]
                del t[:70]
                del t[-remove_time:]
                del t[remove_time:]
                
                tmp = []
                for i in range(len(t)):
                    if t[i] > 0.5: tmp += [t[i]]
                #l = ax.plot(t, label=lab+" "+str(np.mean(tmp))[:4])
                l = ax.plot(t, label="node"+str(j)+" "+str(np.mean(tmp))[:4]+"%")
                if not(np.isnan(np.mean(tmp))):
                    tmps+=[np.mean(tmp)]
                print(lab, np.mean(tmp))
                lines.append(l[0])
                
        leg = ax.legend()

        lined = {}  # Will map legend lines to original lines.
        for legline, origline in zip(leg.get_lines(), lines):
            legline.set_picker(True)  # Enable picking on the legend line.
            legline.set_pickradius(2)
            lined[legline] = origline

        def on_pick(event):
            # On the pick event, find the original line corresponding to the legend
            # proxy line, and toggle its visibility.
            legline = event.artist
            origline = lined[legline]
            visible = not origline.get_visible()
            origline.set_visible(visible)
            # Change the alpha on the line in the legend so we can see what lines
            # have been toggled.
            legline.set_alpha(1.0 if visible else 0.2)
            fig.canvas.draw()

        fig.canvas.mpl_connect('pick_event', on_pick)

        ax.set_ylabel("CPU utilization")
        ax.set_xlabel("time (s)")
        ax.set_title("mean: "+str(np.mean(tmps))+"\nstd: "+str(np.std(tmps)))
        os.system("mkdir -p figs-cpu/"+dirr.split("/")[-2])
        plt.savefig("figs-cpu/"+dirr.split("/")[-2]+"/"+str(procs))
        #plt.show()