#!/bin/bash

# Creates Docker swarm using (6) VirtualBox VMs

set -e

#consul_vm="manager1 manager2 manager3"
consul_vm="manager2"
#app_vm="worker1 worker2"
#log_vm="worker3"
#appNlog_vm="worker1 worker2 worker3"
appNlog_vm="worker1 worker2"

SWARM_MANAGER_IP=$(docker-machine ip manager1)
echo ${SWARM_MANAGER_IP}

docker-machine ssh manager1 "docker swarm init --advertise-addr ${SWARM_MANAGER_IP}"

docker-machine env manager1
eval $(docker-machine env manager1)

MANAGER_SWARM_JOIN=$(docker-machine ssh manager1 "docker swarm join-token manager")
MANAGER_SWARM_JOIN=$(echo ${MANAGER_SWARM_JOIN} | grep -E "(docker).*(2377)" -o)
MANAGER_SWARM_JOIN=$(echo ${MANAGER_SWARM_JOIN//\\/''})
echo ${MANAGER_SWARM_JOIN}

# two other manager nodes
for convm in ${consul_vm}
do
  docker-machine ssh ${convm} ${MANAGER_SWARM_JOIN}
done

WORKER_SWARM_JOIN=$(docker-machine ssh manager1 "docker swarm join-token worker")
WORKER_SWARM_JOIN=$(echo ${WORKER_SWARM_JOIN} | grep -E "(docker).*(2377)" -o)
WORKER_SWARM_JOIN=$(echo ${WORKER_SWARM_JOIN//\\/''})
echo ${WORKER_SWARM_JOIN}

# three worker nodes
for appNlogvm in ${appNlog_vm}
do
  docker-machine ssh ${appNlogvm} ${WORKER_SWARM_JOIN}
done

docker node ls

echo "Script completed..."
