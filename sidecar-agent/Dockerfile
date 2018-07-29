FROM alpine:3.8

RUN apk add --update curl && \
  rm -rf /var/cache/apk/* && \
  curl -L https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz | \
    tar -xzO docker/docker > /usr/local/bin/docker && \
  chmod +x /usr/local/bin/docker

COPY sidecar-agent.sh /usr/local/bin/sidecar-agent.sh
RUN chmod +x /usr/local/bin/sidecar-agent.sh

ENTRYPOINT ["/usr/local/bin/sidecar-agent.sh"]
