#!/bin/bash
RED='\033[1;31m' # alarm
GRN='\033[1;32m' # notice
YEL='\033[1;33m' # warning
NC='\033[0m' # No Color

printf "${GRN}==Prepare install kubernetes training environment for ubuntu 18.04==${NC}\n"
MASTERNAME=$RANDOM
sudo hostnamectl set-hostname master${MASTERNAME}.suserancher.lab
IPNAME=$(ifconfig ens4 |grep inet|cut -d ' ' -f 10 |head -n 1)
sudo echo "${IPNAME} master${MASTERNAME}.suserancher.lab" >> /etc/hosts

sleep 1

printf "${RED}==phase 1: modify file system==${NC}\n"

# get os info
OSVERSION=$(cat /etc/lsb-release |grep DISTRIB_CODENAME |cut -d '=' -f 2)

# verify os info
if [ "${OSVERSION}" = 'bionic' ];
then
    printf "${YEL}--OS Verified-- ${NC}\n"
else
    printf "${RED}==OS is not Verified, use ubuntu 18.0==${NC}\n"
    exit 0
fi

# check fstab
printf "${GRN}--check FSTAB for swap-- ${NC}\n"

# backup fstab
printf "${GRN}--backup fstab to fstab.bck-- ${NC}\n"
sudo cp /etc/fstab /etc/fstab.bck

printf "${GRN}--swap off-- ${NC}\n"
sudo swapoff -a

# modify fstab
sudo sed -i.bak '/swap/d' /etc/fstab

# remount all
sudo mount -a

printf "${GRN}==Phase 1 Complete==${NC}\n"
printf "${GRN}==Phase 2: update system and install kubernetes==${NC}\n"
sleep 1

printf "${GRN}--update system--${NC}"
sudo apt-get update && sudo apt-get upgrade -y

printf "${GRN}--Install Docker CE and ContainerD--${NC}\n"
sleep 1

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt-get install ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

printf "${GRN}--install kubeadm, kubelet, and kubectl--${NC}\n"
sleep 1

sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"

sudo sh -c "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"

sudo apt-get update

sudo apt-get install -y kubeadm=1.22.1-00 kubelet=1.22.1-00 kubectl=1.22.1-00

printf "${YEL}--LOCK kubelet kubeadm kubectl version-- ${NC}\n"
sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm init --config kubeadm-cfg.yaml |tee kubeadminfo.txt

sleep 6

printf "${GRN}--config CLI environment-- ${NC}\n"

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo 'source <(kubectl completion bash)' >>$HOME/.bashrc
echo "PS1='\[\033[01;32m\]student@master\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >>$HOME/.bashrc

source $HOME/.bashrc

printf "${GRN}--USE calico CNI-- ${NC}\n"
kubectl apply -f calico.yaml

printf "${GRN}--wait for pods READY for few seconds-- ${NC}\n"
sleep 1m
kubectl get node

printf "${GRN}--init measure server-- ${NC}\n"
kubectl apply -f components.yaml
printf "${YEL}--measure server container will up until worker joined.-- ${NC}\n"

printf "${GRN}--init ingress controller: traefik-- ${NC}\n"
kubectl create -f ingress.rbac.yaml
kubectl create -f traefik-ds.yaml
printf "${YEL}--traefik will up until worker joined.-- ${NC}\n"

printf "${GRN}--setup keypair-- ${NC}\n"
ssh-keygen -t dsa -N "" -f $HOME/.ssh/k8s

printf "${GRN}==Installation Completed==${NC}\n"
printf "${YEL}1. master node setup, run worker.sh to setup worker.${NC}\n"
printf "${YEL}2. if you need kubeadm info, check kubeadminfo.txt${NC}\n"
printf "${YEL}3. if you need join worker and token expired, regen it, kubeadm --help will help\n"
printf "${YEL}4. when worker.sh done, run join command on worker below.${NC}\n"
printf "${GRN}==join worker command==${NC}\n"
tail kubeadminfo.txt -n 2

printf "${GRN}--taint master if required-- ${NC}\n"
echo "kubectl taint node --all node-role.kubernetes.io/master-"
