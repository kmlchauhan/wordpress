#!/bin/bash

# Installs Consul Agents on all nodes in swarm
# (3) Consul Server Agents and (3) Consul Client Agents

# set -e

#vms=( "manager1" "manager2" "manager3" "worker1" "worker2" "worker3" )
#consul_vm="manager1 manager2 manager3"

SWARM_MANAGER_IP=$(docker-machine ip manager1)
echo ${SWARM_MANAGER_IP}

# initial consul server
consul_server="consul-server1"

docker-machine env manager1
eval $(docker-machine env manager1)

docker run -d \
  --net=host \
  --hostname ${consul_server} \
  --name ${consul_server} \
  --restart=on-failure:3 \
  --env 'CONSUL_ALLOW_PRIVILEGED_PORTS=' \
  --env "SERVICE_IGNORE=true" \
  --env "CONSUL_CLIENT_INTERFACE=eth0" \
  --env "CONSUL_BIND_INTERFACE=eth1" \
  --volume consul_data:/consul/data \
  --publish 8500:8500 \
  consul:latest \
  consul agent -server -ui \
    -dns-port=53 \
    -bootstrap-expect=3 \
    -client=0.0.0.0 \
    -advertise=${SWARM_MANAGER_IP} \
    -data-dir="/consul/data"

# next two consul servers
consul_servers="consul-server2 consul-server3"
consul_vm="manager2 manager3"
i=0
for convm in ${consul_vm}
do
  docker-machine env ${convm}
  eval $(docker-machine env ${convm})

  docker run -d \
    --net=host \
    --hostname ${consul_servers[i]} \
    --name ${consul_servers[i]} \
    --restart=on-failure:3 \
    --env 'CONSUL_ALLOW_PRIVILEGED_PORTS=' \
    --env "SERVICE_IGNORE=true" \
    --env "CONSUL_CLIENT_INTERFACE=eth0" \
    --env "CONSUL_BIND_INTERFACE=eth1" \
    --volume consul_data:/consul/data \
    --publish 8500:8500 \
    consul:latest \
    consul agent -server -ui \
      -dns-port=53 \
      -client=0.0.0.0 \
      -advertise='{{ GetInterfaceIP "eth1" }}' \
      -retry-join=${SWARM_MANAGER_IP} \
      -data-dir="/consul/data"
  let "i++"
done

# three consul clients
consul_clients="consul-client1 consul-client2 consul-client3"
appNlog_vm="worker1 worker2 worker3"

i=0
for appNlogvm in ${appNlog_vm}
do
  docker-machine env ${appNlogvm}
  eval $(docker-machine env ${appNlogvm})

  docker run -d \
    --net=host \
    --hostname ${consul_clients[i]} \
    --name ${consul_clients[i]} \
    --restart=on-failure:3 \
    --env 'CONSUL_ALLOW_PRIVILEGED_PORTS=' \
    --env "SERVICE_IGNORE=true" \
    --env "CONSUL_CLIENT_INTERFACE=eth0" \
    --env "CONSUL_BIND_INTERFACE=eth1" \
    --volume consul_data:/consul/data \
    consul:latest \
    consul agent -client=0.0.0.0 \
      -dns-port=53 \
      -advertise='{{ GetInterfaceIP "eth1" }}' \
      -retry-join=${SWARM_MANAGER_IP} \
      -data-dir="/consul/data"
  let "i++"
done

docker-machine env manager1
eval $(docker-machine env manager1)
docker exec -it consul-server1 consul members

echo "Script completed..."
