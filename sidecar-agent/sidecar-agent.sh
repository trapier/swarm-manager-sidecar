#!/usr/bin/env sh

SIDECAR_NAME=swarm-manager-sidecar

# returns id of running container name
running_container_id_from_name() {
  docker container ls -qf name=$1 --no-trunc
}

# waits for a container with a given name to start
# returns container id
wait_for_start_by_name() {
    container_name=$1
    events_fifo=events-$RANDOM
    mkfifo ${events_fifo}
    echo "waiting for ${container_name} to (re)start" >&2
    docker events -f event=start -f type=container -f container=${container_name} > ${events_fifo} &
    events_pid=$!
    read -r _ _ _ swarm_manager_id _ _ < ${events_fifo}
    kill ${events_pid}
    rm ${events_fifo}
    echo ${swarm_manager_id}
}

# starts the sidecar
# returns container id
start_sidecar() {
    docker pull ${REFERENCE_PREFIX}swarm-manager-sidecar:latest >&2
    docker rm -f ${SIDECAR_NAME} &>/dev/null
    sidecar_id=$(docker run -d \
                   --stop-timeout 3 \
                   --network container:ucp-swarm-manager \
                   --cap-add NET_ADMIN \
                   --mount type=volume,source=ucp-node-certs,destination=/certs \
                   --name ${SIDECAR_NAME} \
                   ${REFERENCE_PREFIX}swarm-manager-sidecar:latest)
    docker cp /nginx.conf ${sidecar_id}:/etc/nginx/nginx.conf &>/dev/null
    docker exec ${sidecar_id} nginx -s reload >&2
    echo ${sidecar_id}
}

# signal sidecar to stop before exiting
shutdown(){
  kill ${mainloop_pid}
  docker stop ${sidecar_id}
}
trap shutdown TERM INT

# block if motorcycle isn't running yet
swarm_manager_id=$(running_container_id_from_name ucp-swarm-manager)
test -z "${swarm_manager_id}" && swarm_manager_id=$(wait_for_start_by_name "ucp-swarm-manager")

# start a new sidecar
sidecar_id=$(running_container_id_from_name ${SIDECAR_NAME})
test -n "${sidecar_id}" && docker stop "${sidecare_id}"
sidecar_id=$(start_sidecar)

# main loop
while true; do
   swarm_manager_id=$(wait_for_start_by_name "ucp-swarm-manager")
   docker stop ${sidecar_id}
   sidecar_id=$(start_sidecar)
done &
mainloop_pid=$!
wait
