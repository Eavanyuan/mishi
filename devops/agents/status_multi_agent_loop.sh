#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${ROOT_DIR}/collab/handoff/runtime"
PID_FILE="${RUNTIME_DIR}/loop.pid"
LOOP_LOG="${RUNTIME_DIR}/loop.log"
ORCH_LOG="${RUNTIME_DIR}/orchestrator.log"

if [[ -f "${PID_FILE}" ]]; then
  pid="$(cat "${PID_FILE}" 2>/dev/null || true)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    echo "status: running"
    echo "pid: ${pid}"
  else
    echo "status: stopped (stale pid file)"
  fi
else
  echo "status: stopped"
fi

echo "runtime_dir: ${RUNTIME_DIR}"
[[ -f "${LOOP_LOG}" ]] && echo "loop_log: ${LOOP_LOG}"
[[ -f "${ORCH_LOG}" ]] && echo "orchestrator_log: ${ORCH_LOG}"
