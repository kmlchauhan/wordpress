#!/bin/bash

# Creates (6) VirtualBox VMs

set -e

#vms="manager1 manager2 manager3 worker1 worker2 worker3"
#consul_vm="manager1 manager2 worker1 worker2 worker3"

consul_vm="manager1 manager2 worker1 worker2"

#app_vm="worker1 worker2"
#log_vm="worker3"

# minimally sized for managers
for convm in ${consul_vm}
do
  docker-machine create \
    --driver virtualbox \
    --virtualbox-memory "512" \
    --virtualbox-cpu-count "1" \
    --virtualbox-disk-size "5000" \
    --engine-label purpose=consul \
    ${convm}
done

# medium sized for apps
#for appvm in ${app_vm}
#do
#  docker-machine create \
#    --driver virtualbox \
#    --virtualbox-memory "512" \
#    --virtualbox-cpu-count "1" \
#    --virtualbox-disk-size "10000" \
#    --engine-label purpose=applications \
#    ${appvm}
#done

# larger for ELK Stack
#for logvm in ${log_vm}
#do
#  docker-machine create \
#    --driver virtualbox \
#    --virtualbox-memory "512" \
#    --virtualbox-cpu-count "1" \
#    --virtualbox-disk-size "10000" \
#    --engine-label purpose=logging \
#    ${logvm}
#done

# fix vm.max when ELK Stack is installed on worker3
docker-machine ssh worker3 sudo sysctl -w vm.max_map_count=262144
docker-machine ssh worker3 sudo sysctl -n vm.max_map_count

docker-machine ls

echo "Script completed..."
