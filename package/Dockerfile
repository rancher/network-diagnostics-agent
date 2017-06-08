FROM rancher/agent-base:v0.3.0
RUN apt-get update && apt-get install bzip2
COPY network-support-agent collect-info-ipsec.sh /usr/bin/
RUN mkdir -p /logs \
    && chmod +x /usr/bin/collect-info-ipsec.sh
CMD ["network-support-agent"]
