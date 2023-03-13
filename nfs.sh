#!/bin/bash
RED='\033[1;31m' # alarm
GRN='\033[1;32m' # notice
YEL='\033[1;33m' # warning
NC='\033[0m' # No Color

printf "${RED}==install NFS Service==${NC}\n"
sudo apt install nfs-kernel-server -y
sudo mkdir -p /mnt/nfs_share
sudo chown -R nobody:nogroup /mnt/nfs_share/
sudo chmod 777 /mnt/nfs_share/
sudo sed -i 's/# Domain = localdomain/Domain = training.inwinstack/g' /etc/idmapd.conf
echo "training files" > /mnt/nfs_share/nfsfile.txt
echo "/mnt/nfs_share *(rw,sync,no_root_squash,subtree_check)" >> /etc/exports
sudo systemctl restart nfs-server.service
sudo systemctl enable nfs-server.service

printf "${GRN}==installation completed==${NC}\n"
IP=$(ifconfig ens4 |grep inet|cut -d ' ' -f 10 |head -n 1)
printf "${GRN}==NFS IP: ${IP} ==\n"
echo "sudo mount -t nfs ${IP}:/mnt/nfs_share /mnt" > nfs.info
printf "${GRN}==export /mnt/nfs_share for nfs==${NC}\n"
printf "${YEL}==you don't need manually mount nfs==${NC}\n"
