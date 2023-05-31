import parse

dirrs = ["/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-snap/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-snap-b/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-mul/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary-mul-b/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary/",
    "/home/nivek/Workspace/distristorage/cloudlabs/ceph/ro/data-vary2/"]

for dirr in dirrs:
    v={}
    print(dirr)
    for i in range(1, 11, 3):
        v[i] = 0
        for j in range(i+1):
            with open(dirr+"dd"+str(i)+str(j), "r") as f:
                lines = f.readlines()
                a,_,b = lines[-11:][:3]
                vi=None
                if "MiB/s" in b:
                    bw_r = parse.parse("bw={:g}MiB/s", b.split()[1])
                    vi = [bw_r[0]*1000]
                else:
                    bw_r = parse.parse("bw={:g}KiB/s", b.split()[1])
                    vi = [bw_r[0]]
                
                v[i] += vi[0]
        print(i, v[i]/(i+1))
