#!/bin/bash
set -e

NETWORK="${FRIGATE_NETWORK:-testnet4}"
HOME_DIR="/data/frigate"
CONFIG_FILE="${HOME_DIR}/config.toml"
BITCOIN_DATA_DIR="${FRIGATE_BITCOIN_DATA_DIR:-/data/.bitcoin}"

mkdir -p "${HOME_DIR}"

DEFAULT_START_HEIGHT=0
case "${NETWORK}" in
    mainnet) DEFAULT_START_HEIGHT=709632 ;;
    *) DEFAULT_START_HEIGHT=0 ;;
esac
START_HEIGHT="${FRIGATE_START_HEIGHT:-${DEFAULT_START_HEIGHT}}"

if [ -z "${APP_BITCOIN_NODE_IP}" ] || [ -z "${APP_BITCOIN_RPC_PORT}" ]; then
    echo "ERROR: APP_BITCOIN_NODE_IP and APP_BITCOIN_RPC_PORT must be set"
    exit 1
fi

AUTH_BLOCK=""
if [ -d "${BITCOIN_DATA_DIR}" ]; then
    COOKIE_FILE=$(find "${BITCOIN_DATA_DIR}" -maxdepth 2 -name '.cookie' -type f 2>/dev/null | head -1)
    if [ -n "${COOKIE_FILE}" ]; then
        echo "Cookie auth: found ${COOKIE_FILE}, using dataDir=${BITCOIN_DATA_DIR}"
        AUTH_BLOCK="authType = \"COOKIE\"
dataDir = \"${BITCOIN_DATA_DIR}\""
    fi
fi

if [ -z "${AUTH_BLOCK}" ]; then
    if [ -z "${APP_BITCOIN_RPC_USER}" ] || [ -z "${APP_BITCOIN_RPC_PASS}" ]; then
        echo "ERROR: no .cookie found at ${BITCOIN_DATA_DIR} and APP_BITCOIN_RPC_USER/PASS not set"
        exit 1
    fi
    echo "Userpass auth: APP_BITCOIN_RPC_USER=${APP_BITCOIN_RPC_USER}"
    AUTH_BLOCK="authType = \"USERPASS\"
auth = \"${APP_BITCOIN_RPC_USER}:${APP_BITCOIN_RPC_PASS}\""
fi

ZMQ_BLOCK=""
if [ -n "${APP_BITCOIN_ZMQ_SEQUENCE_PORT}" ]; then
    ZMQ_BLOCK="zmqSequenceEndpoint = \"tcp://${APP_BITCOIN_NODE_IP}:${APP_BITCOIN_ZMQ_SEQUENCE_PORT}\""
    echo "ZMQ pubsequence: tcp://${APP_BITCOIN_NODE_IP}:${APP_BITCOIN_ZMQ_SEQUENCE_PORT}"
fi

cat > "${CONFIG_FILE}" <<EOF
[core]
connect = true
server = "http://${APP_BITCOIN_NODE_IP}:${APP_BITCOIN_RPC_PORT}"
${AUTH_BLOCK}
${ZMQ_BLOCK}

[index]
startHeight = ${START_HEIGHT}

[scan]
computeBackend = "${FRIGATE_COMPUTE_BACKEND:-CPU}"

[server]
port = ${FRIGATE_PORT:-57001}
EOF

if [ -n "${FRIGATE_BACKEND_ELECTRUM}" ]; then
    echo "backendElectrumServer = \"${FRIGATE_BACKEND_ELECTRUM}\"" >> "${CONFIG_FILE}"
fi

echo "Frigate starting on network=${NETWORK} startHeight=${START_HEIGHT}"
exec /opt/frigate/bin/frigate -n "${NETWORK}" -d "${HOME_DIR}"
