#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${ROOT_DIR}/collab/handoff/runtime"
LOG_FILE="${RUNTIME_DIR}/loop.log"
PID_FILE="${RUNTIME_DIR}/loop.pid"
ORCH_SCRIPT="${ROOT_DIR}/devops/agents/mishi_multi_agent_orchestrator.sh"

INTERVAL_SECONDS="${INTERVAL_SECONDS:-1800}"

mkdir -p "${RUNTIME_DIR}"

if [[ -f "${PID_FILE}" ]]; then
  pid="$(cat "${PID_FILE}" 2>/dev/null || true)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    echo "loop already running, pid=${pid}"
    exit 0
  fi
fi

nohup bash -c '
set -euo pipefail
while true; do
  "'"${ORCH_SCRIPT}"'" || true
  sleep "'"${INTERVAL_SECONDS}"'"
done
' >>"${LOG_FILE}" 2>&1 &

echo $! >"${PID_FILE}"
echo "started multi-agent loop, pid=$(cat "${PID_FILE}")"
echo "log: ${LOG_FILE}"
