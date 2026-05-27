FROM eclipse-temurin:25-jre-jammy

ENV FRIGATE_VERSION=1.5.2
ENV FRIGATE_HOME=/data

RUN groupadd --gid 1000 frigate && useradd --uid 1000 --gid frigate --shell /bin/bash frigate

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-x86_64.tar.gz \
    && tar -xzf frigate-${FRIGATE_VERSION}-x86_64.tar.gz \
    && rm frigate-${FRIGATE_VERSION}-x86_64.tar.gz

RUN mkdir -p ${FRIGATE_HOME}/db ${FRIGATE_HOME}/cache \
    && chown -R frigate:frigate /opt/frigate ${FRIGATE_HOME}

USER frigate

EXPOSE 50001 50002

WORKDIR ${FRIGATE_HOME}

ENTRYPOINT ["/opt/frigate/bin/frigate", "-d", "/data"]