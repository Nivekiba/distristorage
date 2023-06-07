#!/bin/bash

disk_img=$1


sudo ./setup_rocksdb.exp non $disk_img


recordcount=1000000
target=500
workload_dir=/root/ycsb-db

rocks_config="
rocksdb.dir=$workload_dir
recordcount=$recordcount
threadcount=15
fieldcount=150
fieldlength=150
measurementtype=timeseries
timeseries.granularity=2000
    "

sudo ./write_rocksdb.exp non $disk_img "$rocks_config"
