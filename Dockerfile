FROM debian:bookworm-slim

ARG FRIGATE_VERSION=1.5.2
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libfontconfig1 \
        libfreetype6 \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ARCH=x86_64 ;; \
        arm64) ARCH=aarch64 ;; \
        *) echo "unsupported arch ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/frigate.tar.gz \
        "https://github.com/sparrowwallet/frigate/releases/download/${FRIGATE_VERSION}/frigate-${FRIGATE_VERSION}-${ARCH}.tar.gz"; \
    tar -xzf /tmp/frigate.tar.gz -C /opt; \
    rm /tmp/frigate.tar.gz

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data
EXPOSE 57001

ENTRYPOINT ["/entrypoint.sh"]
