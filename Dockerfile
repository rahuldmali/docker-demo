FROM xaxiseng/base-centos7:1.0.0-34

MAINTAINER  Prahlad Kumar <prahladk@cybage.com>

# Install the basic requirements
RUN  yum -y update && yum -y install epel-release && yum -y install pwgen wget logrotate && yum -y install nss_wrapper gettext && yum clean all

#Install Erlang
RUN yum -y install erlang

# Setup rabbitmq-server
RUN useradd -d /var/lib/rabbitmq -u 1001 -o -g 0 rabbitmq


RUN DIR=$(mktemp -d) \
    && cd ${DIR} \
    && rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc \
    && wget https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_12/rabbitmq-server-3.6.12-1.el7.noarch.rpm \
    && yum install -y rabbitmq-server-3.6.12-1.el7.noarch.rpm \
    && rabbitmq-plugins enable rabbitmq_management \
    && echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config \
    && rm -rf ${DIR}

# Send the logs to stdout
ENV RABBITMQ_LOGS=- RABBITMQ_SASL_LOGS=-

# Create directory for scripts and passwd template
RUN mkdir -p /tmp/rabbitmq

#RUN /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management

ADD entrypoint.sh /tmp/rabbitmq/entrypoint.sh

# Set permissions for openshift run
RUN chown -R 1001:0 /etc/rabbitmq && chown -R 1001:0 /var/lib/rabbitmq  && chmod -R ug+rw /etc/rabbitmq && \
    chmod -R ug+rw /var/lib/rabbitmq && find /etc/rabbitmq -type d -exec chmod g+x {} + && \
    find /var/lib/rabbitmq -type d -exec chmod g+x {} +

# Set  workdir
WORKDIR /var/lib/rabbitmq

# 
# expose some ports
#
# 5672 rabbitmq-server - amqp port
# 15672 rabbitmq-server - for management plugin
# 4369 epmd - for clustering
# 25672 rabbitmq-server - for clustering
EXPOSE 5672 15672 4369 25672

# Add passwd template file for nss_wrapper
ADD passwd.template /tmp/rabbitmq/passwd.template

# Set permissions for scripts directory
RUN chown -R 1001:0 /tmp/rabbitmq && chmod -R ug+rwx /tmp/rabbitmq && \
    find /tmp/rabbitmq -type d -exec chmod g+x {} +

USER 1001
#
# entrypoint/cmd for container
CMD ["/tmp/rabbitmq/entrypoint.sh"]
