# Summary

auto-injected nginx sidecar proxy for ucp-swarm-manager, configured to change 500 on /containers/create to 404

# Usage

## Setup
1. edit `.env`, setting `REFERENCE_PREFIX` to `dtr_hostname/org_or_user/`.
2. source UCP client bundle

## Deploy
build, push and deploy service:

    ```
    ./deploy.sh  buildpush
    ```

## Undeploy

```
docker service rm swarm-manager-sidecar-agent
```

# Design

deployment script:
- defines nginx sidecar swarm config
- deploys sidecar agent service

sidecar agent service:
- spec:
  - mode global, constrained to managers
  - nginx sidecar config
  - bind mounts /var/run/docker.sock
1. deploy nginx sidecar container with `--network container:ucp-swarm-manager`
2. `docker cp` nginx config from swarm config into sidecar, and triggers nginx reload
3. watche docker container events and redeploys sidecar container when ucp-swarm-manager is started with a different container id
4. intercept sigterm and stop sidecar

sidecar:
- spec:
    - shares network with ucp-swarm-manager
    - cap-add NET_ADMIN
    - mounts ucp-node-certs volume
1. configures iptables to intercept ingress tcp to 2376, redirects to nginx
2. nginx ssl proxy_pass:
    - verify client certs
    - support upgrade to tcp
    - change 500 on /containers/create to 404
3. intercept SIGTERM and deconfigures iptables before exit

# Testing Status
Lightly.  With UCP 2.2.11.  Still some rough edges, particularly around use of conntrack to flush at sidecar start time. Would consider this a proof-of-concept at the moment.
