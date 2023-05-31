sudo su

update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

sleep 5
sudo apt-get update -y
sudo apt install qemu qemu-kvm -y
sudo apt install nfs-kernel-server -y
sudo apt install nfs-common -y
sudo apt install git build-essential -y
sudo apt install libguestfs-tools -y
sudo apt install pkg-config libglib2.0-dev libpixman-1-dev libgtk-3-dev expect jq socat -y
sudo apt install openssh-server glusterfs-server sysstat mutt -y

systemctl enable --now sshd
service glusterd start

sudo sed -i 's/false/true/' /etc/default/sysstat
service sysstat restart

echo "
#!/bin/bash

sar -db 15 > sartest
" > /root/sar.sh

chmod +x /root/sar.sh

# allow root ssh
if grep -Fxq "AllowGroups" /etc/ssh/sshd_config
then
        echo "test"
else
        echo "AllowGroups root" >> /etc/ssh/sshd_config
fi

service restart sshd
