FROM nginx:1.15.2

RUN apt-get update && \
    apt-get install -y conntrack iptables iproute2

COPY sidecar-entrypoint.sh /usr/local/bin/sidecar-entrypoint.sh

RUN chmod +x /usr/local/bin/sidecar-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/sidecar-entrypoint.sh"]
