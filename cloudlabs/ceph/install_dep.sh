#!/bin/bash

update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

rm /etc/apt/sources.list.d/* -rf

#sleep 5

#sudo apt-get update -y
#wget https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
#sudo install ubuntu-mainline-kernel.sh /usr/local/bin/
#sudo ubuntu-mainline-kernel.sh -c
#sudo ubuntu-mainline-kernel.sh -i 5.19.17 --yes
#sudo apt --fix-broken install -y
#sudo shutdown -h now
#sleep 5

sudo apt-get update -y
sudo apt install qemu qemu-kvm python3-pip -y
sudo apt install nfs-kernel-server -y
sudo apt install nfs-common -y
sudo apt install git build-essential -y
sudo apt install libguestfs-tools python3-pip -y
sudo apt install pkg-config libglib2.0-dev libpixman-1-dev libgtk-3-dev expect jq socat sysstat -y
sudo apt install openssh-server ansible sysstat ceph-common ceph-base librbd1 -y
pip3 install pythonping
pip3 install numpy
pip3 install etcd3
# launching sysstat monitoring
sudo sed -i 's/false/true/' /etc/default/sysstat
service sysstat restart


systemctl enable --now sshd
# installing docker
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -sc) stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo systemctl enable --now docker

echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl reload sshd
