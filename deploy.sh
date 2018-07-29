#!/usr/bin/env sh
set -e

test -e ./.env && source ./.env

if expr match $1 'build' &>/dev/null; then
    for dir in */; do 
        image=swarm-manager-${dir%/}
        docker build -t ${REFERENCE_PREFIX}${image} ${dir}
        if expr match $1 '.*push.*' &>/dev/null; then
            docker push ${REFERENCE_PREFIX}${image}
        fi
    done
    if expr match $1 ".*only" &>/dev/null; then exit; fi
fi

existing_config=$(docker config ls -f name=swarm-manager-sidecar-nginx --format {{.Name}} |sort -V |tail -n1)
if [ -z "${existing_config}" ]; then
    docker config create swarm-manager-sidecar-nginx-1 sidecar/nginx.conf
    config=swarm-manager-sidecar-nginx-1 
else
    echo using ${existing_config} in 5 seconds
#    sleep 5
    config=${existing_config}
fi

docker service rm swarm-manager-sidecar-agent  || true
docker service create \
  --detach=true \
  --name swarm-manager-sidecar-agent \
  --mode global \
  --constraint node.role==manager \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --config src=${config},target=/nginx.conf \
  --env REFERENCE_PREFIX=${REFERENCE_PREFIX} \
  ${REFERENCE_PREFIX}swarm-manager-sidecar-agent:latest
