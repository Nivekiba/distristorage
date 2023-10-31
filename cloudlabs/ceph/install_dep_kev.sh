#!/bin/bash

update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

rm /etc/apt/sources.list.d/* -rf

## ====== start kernel upgrade ======= ##

#sleep 5

#sudo apt-get update -y
#wget https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
#sudo install ubuntu-mainline-kernel.sh /usr/local/bin/
#sudo ubuntu-mainline-kernel.sh -c
#sudo ubuntu-mainline-kernel.sh -i 5.19.17 --yes
#sudo apt --fix-broken install -y
#sudo shutdown -h now
#sleep 5

## ===== stop kernel upgrade ===== ##

sudo apt-get update -y
sudo apt install qemu qemu-kvm python3-pip -y
sudo apt install nfs-kernel-server -y
sudo apt install nfs-common -y
sudo apt install git build-essential -y
sudo apt install libguestfs-tools python3-pip -y
sudo apt install pkg-config libglib2.0-dev libpixman-1-dev libgtk-3-dev expect jq socat sysstat -y
sudo apt install openssh-server ansible sysstat librbd1 -y
sudo pip3 install pythonping
sudo pip3 install numpy
sudo pip3 install etcd3
# launching sysstat monitoring
sudo sed -i 's/false/true/' /etc/default/sysstat
sudo service sysstat restart


sudo systemctl enable --now sshd
# installing docker
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -sc) stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo systemctl enable --now docker

sudo echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sudo systemctl reload sshd

# rebuild mydata dir
sudo umount /mydata
sudo lvremove /dev/emulab/node0-bs --yes
sudo vgremove emulab --yes
sudo vgcreate emulab /dev/sdb
sudo lvcreate -L 400G -n node0-bs emulab

sudo mkfs.ext4 -F /dev/sda4
sudo mount /dev/sda4 /mydata

# build etcd-cpp-api
cd /mydata
sudo apt-get install cmake ninja-build libboost-all-dev libssl-dev -y
sudo apt-get install -y libgrpc-dev \
        libgrpc++-dev \
        libprotobuf-dev \
        protobuf-compiler-grpc

sudo apt-get install -y libcpprest-dev

sudo rm -rf etcd-cpp-apiv3
sudo git clone https://github.com/etcd-cpp-apiv3/etcd-cpp-apiv3.git
sudo git config --global --add safe.directory /mydata/etcd-cpp-apiv3

cd etcd-cpp-apiv3
sudo mkdir build
cd build
sudo cmake .. -DBUILD_ETCD_CORE_ONLY=ON
sudo make -j$(nproc) && sudo make install

# build my ceph repo

cd /mydata

sudo rm -rf ceph
sudo git clone https://github.com/nivekiba/ceph
#sudo git clone https://github.com/ceph/ceph
sudo git config --global --add safe.directory /mydata/ceph

cd ceph

sudo git submodule update --init --recursive
sudo cp /users/nivekiba/install-deps.sh ./insta2.sh
#sudo cp /root/install-deps.sh ./insta2.sh

sudo chmod +x ./install-deps.sh
sudo chmod +x ./insta2.sh
sudo ./install-deps.sh

sudo apt install -f -y
sudo ./insta2.sh > /tmp/bouzi

sudo apt install libthrift-0.13.0 -y

sudo apt -y install libboost-filesystem-dev
sudo apt install libibverbs-dev -y
sudo apt install python3-routes python3-rados -y # take care of this line, sometimes python3-rados will install incompatible version compared to standalone built of ceph
sudo pip3 install prettytable
sudo pip3 install bcrypt

sudo pip3 install asyncssh
sudo pip3 install pyjwt
sudo pip3 install python-dateutil

sudo rm -rf /usr/lib/python3/dist-packages/OpenSSL
sudo pip3 install pyopenssl
sudo pip3 install pyopenssl --upgrade

sudo pip install cryptography==40.0.2 --upgrade

sudo ./do_cmake.sh
cd build
sudo ninja -j 0


sudo echo "export PATH=$PATH:/mydata/ceph/build/bin" | sudo tee ~/.bashrc
sudo echo "export PATH=$PATH:/mydata/ceph/build/bin" | sudo tee /root/.bashrc

export PATH=$PATH:/mydata/ceph/build/bin


# change docker data directory
mkdir /mydata/docker
sudo systemctl stop docker

sudo mv /var/lib/docker/ /mydata/docker/
sudo ln -s /mydata/docker/ /var/lib/docker

sudo systemctl start docker

# load librbd.so
sudo mv /usr/lib/x86_64-linux-gnu/librbd.so.1 /usr/lib/x86_64-linux-gnu/librbd.so.1.tmp
sudo mv /usr/lib/x86_64-linux-gnu/librbd.so   /usr/lib/x86_64-linux-gnu/librbd.so.tmp
sudo ln -s /mydata/ceph/build/lib/librbd.so.1.18.0 /usr/lib/x86_64-linux-gnu/librbd.so.1
sudo ln -s /usr/lib/x86_64-linux-gnu/librbd.so.1 /usr/lib/x86_64-linux-gnu/librbd.so
sudo cp lib/librados.so.2 /lib/x86_64-linux-gnu/
