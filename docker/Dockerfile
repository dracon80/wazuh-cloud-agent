FROM amazonlinux:2023

ARG AGENT_VERSION=4.7.3-1.x86_64

RUN yum -y update && yum -y install shadow-utils procps && yum -y clean all
RUN curl -o wazuh-agent.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-${AGENT_VERSION}.rpm && rpm -ihv wazuh-agent.rpm

WORKDIR /wazuh-agent
COPY wazuh-agent/* /wazuh-agent/

ENTRYPOINT [ "/wazuh-agent/entrypoint.sh" ]