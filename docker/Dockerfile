FROM amazonlinux:2023

ARG AGENT_VERSION=4.7.4-1.x86_64

RUN yum -y update && yum -y install shadow-utils procps && yum -y clean all
RUN curl -o wazuh-agent.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-${AGENT_VERSION}.rpm && rpm -ihv wazuh-agent.rpm

ENTRYPOINT ["./entrypoint.sh"]