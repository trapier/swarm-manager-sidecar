#!/usr/bin/env sh
set -x

IPTABLES_COMMENT="swarm-sidecar"

# reroute inbound traffic destined to swarm manager to nginx on lo port 33333
# make the replies from nginx look like they came from eth0 on port 2375 
setup_iptables(){
    iptables -w1 -t nat -I PREROUTING  -p tcp -m tcp --dport 2375  -j DNAT --to-destination :33333 -m comment --comment ${IPTABLES_COMMENT}
    conntrack -F
}

# remove any nat rules with IPTABLES_COMMENT
remove_iptables(){
    for chain in PREROUTING; do
        for rule_number in $(iptables -w1 --line-numbers -t nat -nL ${chain} |awk "/${IPTABLES_COMMENT}/ {print \$1}"); do
            iptables -w1 -t nat -D ${chain} ${rule_number}
        done
    done
}

# cleanup iptables rules before exiting
shutdown() {
    remove_iptables
    nginx -s stop
}
trap shutdown TERM INT

eth0_ip=$(ip -br a sh dev eth0 |awk '{print $NF}' |cut -d/ -f1)
remove_iptables
setup_iptables
nginx -g 'daemon off;' &
wait
