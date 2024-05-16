FROM ubuntu:noble AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg2 \
      protobuf-compiler && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | \
      tee /etc/apt/sources.list.d/yarn.list > /dev/null && \
    apt-get update && apt-get install -y --no-install-recommends yarn && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd -ms /bin/bash ubuntu && \
    mkdir -p /opt/mahjongsoul-sniffer && \
    chown -R ubuntu /opt/mahjongsoul-sniffer && \
    mkdir -p /srv/mahjongsoul-sniffer && \
    chown -R ubuntu /srv/mahjongsoul-sniffer

COPY --chown=ubuntu . /opt/mahjongsoul-sniffer.orig/

USER ubuntu

WORKDIR /opt/mahjongsoul-sniffer

RUN /opt/mahjongsoul-sniffer.orig/api-visualizer/build.sh

FROM ubuntu:noble

RUN apt-get update && apt-get install -y \
      protobuf-compiler \
      python3 \
      python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    pip3 install -U pip && \
    useradd -ms /bin/bash ubuntu && \
    mkdir -p /opt/mahjongsoul-sniffer && \
    chown -R ubuntu /opt/mahjongsoul-sniffer && \
    mkdir -p /var/log/mahjongsoul-sniffer && \
    chown -R ubuntu /var/log/mahjongsoul-sniffer && \
    mkdir -p /srv/mahjongsoul-sniffer && \
    chown -R ubuntu /srv/mahjongsoul-sniffer

COPY ./api-visualizer/requirements.txt /opt/mahjongsoul-sniffer/api-visualizer/

RUN pip3 install -r /opt/mahjongsoul-sniffer/api-visualizer/requirements.txt

COPY --from=builder /opt/mahjongsoul-sniffer /opt/mahjongsoul-sniffer

USER ubuntu

WORKDIR /opt/mahjongsoul-sniffer

ENV PYTHONPATH=/opt/mahjongsoul-sniffer
ENV FLASK_APP=/opt/mahjongsoul-sniffer/api-visualizer/web-server
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

ENTRYPOINT ["api-visualizer/run-web-server.sh"]
