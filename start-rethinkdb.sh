#!/usr/bin/env ash
set -o pipefail

if [ -z ${POD_NAMESPACE+x} ]; then
  echo "POD_NAMESPACE has not been set"
  exit 1
fi

if [ -z ${POD_IP+x} ]; then
  echo "POD_IP has not been set"
  exit 1
fi

if [ -z ${SERVICE_NAME+x} ]; then
  echo "SERVICE_NAME has not been set"
  exit 1
fi

if [ -z ${POD_NAME+x} ]; then
  echo "POD_NAME has not been set"
  exit 1
fi

SERVER_NAME=$(echo ${POD_NAME} | sed 's/-/_/g')

echo "Using additional CLI flags: ${@}"
echo "Pod IP: ${POD_IP}"
echo "Pod namespace: ${POD_NAMESPACE}"
echo "Using service name: ${SERVICE_NAME}"
echo "Using server name: ${SERVER_NAME}"

echo "Searching for other rethinkdb nodes..."
SERVICE_ENDPOINTS=$(getent hosts "${SERVICE_NAME}.${POD_NAMESPACE}.svc.cluster.local" | awk '{print $1}')
SERVICE_ENDPOINTS=$(echo ${SERVICE_ENDPOINTS} | sed -e "s/${POD_IP}//g")
SERVICE_ENDPOINTS=$(echo ${SERVICE_ENDPOINTS} | xargs echo | tr -s ' ')

if [ -n "${SERVICE_ENDPOINTS}" ]; then
  echo "Found other nodes: ${SERVICE_ENDPOINTS}"
  SERVICE_ENDPOINTS=$(echo ${SERVICE_ENDPOINTS} | sed -r 's/([0-9.])+/&:29015/g')
  SERVICE_ENDPOINTS=$(echo ${SERVICE_ENDPOINTS} | sed -e 's/^\|[ ]/&--join /g')
else
  echo "No other rethinkdb nodes found"
  if [ -n "${PROXY}" ]; then
    echo "Cannot start a rethinkdb node in proxy mode without other nodes running"
    exit 1
  fi
fi

if [ -z "${PROXY+x}" ]; then
  set -x
  exec rethinkdb \
    --server-name ${SERVER_NAME} \
    --canonical-address ${POD_IP} \
    --bind all \
    ${SERVICE_ENDPOINTS} \
    ${@}
else
  echo "Starting in proxy mode"
  set -x
  exec rethinkdb \
    proxy \
    --canonical-address ${POD_IP} \
    --bind all \
    ${SERVICE_ENDPOINTS} \
    ${@}
fi
