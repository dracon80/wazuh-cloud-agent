FROM amazonlinux:2023

ARG AGENT_VERSION=4.7.4-1.x86_64

RUN yum -y update && yum -y install shadow-utils procps && yum -y clean all
RUN groupadd -g 970 -r -U root wazuh && useradd -u 970 -g 970 -N -r wazuh
RUN curl -o wazuh-agent.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-${AGENT_VERSION}.rpm && rpm -ihv wazuh-agent.rpm

WORKDIR /wazuh-agent
COPY wazuh-agent/* /wazuh-agent/

ENTRYPOINT ["./entrypoint.sh"]