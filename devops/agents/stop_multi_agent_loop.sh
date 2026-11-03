#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PID_FILE="${ROOT_DIR}/collab/handoff/runtime/loop.pid"

if [[ ! -f "${PID_FILE}" ]]; then
  echo "loop is not running (pid file not found)"
  exit 0
fi

pid="$(cat "${PID_FILE}" 2>/dev/null || true)"
if [[ -z "${pid}" ]]; then
  rm -f "${PID_FILE}"
  echo "loop pid is empty, cleaned pid file"
  exit 0
fi

if kill -0 "${pid}" 2>/dev/null; then
  kill "${pid}"
  sleep 1
  if kill -0 "${pid}" 2>/dev/null; then
    kill -9 "${pid}" || true
  fi
  echo "stopped multi-agent loop, pid=${pid}"
else
  echo "process ${pid} not running, cleaned pid file"
fi

rm -f "${PID_FILE}"
