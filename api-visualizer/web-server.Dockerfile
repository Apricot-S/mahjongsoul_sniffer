FROM ubuntu:noble AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg2 \
      protobuf-compiler && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    corepack enable yarn && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/mahjongsoul-sniffer && \
    chown -R ubuntu /opt/mahjongsoul-sniffer && \
    mkdir -p /srv/mahjongsoul-sniffer && \
    chown -R ubuntu /srv/mahjongsoul-sniffer

COPY --chown=ubuntu . /opt/mahjongsoul-sniffer.orig/

USER ubuntu

WORKDIR /opt/mahjongsoul-sniffer

RUN /opt/mahjongsoul-sniffer.orig/api-visualizer/build.sh

FROM ubuntu:noble AS installer

RUN apt-get update && apt-get install -y \
      python3 \
      python3-pip \
      python3-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/mahjongsoul-sniffer

COPY ./api-visualizer/requirements.txt /opt/mahjongsoul-sniffer/api-visualizer/

RUN python3 -m venv /opt/mahjongsoul-sniffer/api-visualizer/.venv && \
    . /opt/mahjongsoul-sniffer/api-visualizer/.venv/bin/activate && \
    pip3 install -U pip && \
    pip3 install -r /opt/mahjongsoul-sniffer/api-visualizer/requirements.txt

FROM ubuntu:noble

RUN apt-get update && apt-get install -y \
      protobuf-compiler \
      python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/mahjongsoul-sniffer && \
    chown -R ubuntu /opt/mahjongsoul-sniffer && \
    mkdir -p /var/log/mahjongsoul-sniffer && \
    chown -R ubuntu /var/log/mahjongsoul-sniffer && \
    mkdir -p /srv/mahjongsoul-sniffer && \
    chown -R ubuntu /srv/mahjongsoul-sniffer

COPY --from=builder /opt/mahjongsoul-sniffer /opt/mahjongsoul-sniffer
COPY --from=installer /opt/mahjongsoul-sniffer/api-visualizer/.venv /opt/mahjongsoul-sniffer/api-visualizer/.venv

USER ubuntu

WORKDIR /opt/mahjongsoul-sniffer

ENV PYTHONPATH=/opt/mahjongsoul-sniffer
ENV FLASK_APP=/opt/mahjongsoul-sniffer/api-visualizer/web-server
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

ENTRYPOINT ["/bin/bash", "-c", "source api-visualizer/.venv/bin/activate && api-visualizer/run-web-server.sh"]
