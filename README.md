# For lab env

## Install
1. git clone https://github.com/po45ke95/initk8s.git && cd initk8sfortraining
2. sudo ./nfs.sh && sudo ./master.sh
3. use sudo ./worker.sh to join workers at 'worker node'.
4. support ease join more workers.

## Env 
1. OS :ubuntu 18.04
2. kubernetes: 1.22.1
3. 1 master, 2 worker
4. 4 core, 8 G RAM 70G local Disk(recommand!)
5. storage: NFS@master
6. ingress controller: traefik
7. measure server installed

## References
1. ingress controller: traefik
2. measure server: here