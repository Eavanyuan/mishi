#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/collab/handoff/runtime"
RUN_LOG="${LOG_DIR}/orchestrator.log"
mkdir -p "${LOG_DIR}"

OPENCLAW_BIN="${OPENCLAW_BIN:-openclaw}"
OPENCLAW_MODE="${OPENCLAW_MODE:---local}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-3600}"
DRY_RUN="${DRY_RUN:-0}"

ROLE_ORDER=("pm-agent" "arch-agent" "backend-agent" "frontend-agent" "app-agent")

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing command: $1" >&2
    exit 1
  fi
}

append_log() {
  local level="$1"
  shift
  local msg="$*"
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${level}" "${msg}" | tee -a "${RUN_LOG}"
}

run_agent_turn() {
  local agent_id="$1"
  local mission="$2"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  local prompt_file="${ROOT_DIR}/docs/agents/prompts/${agent_id}.prompt.md"
  if [[ ! -f "${prompt_file}" ]]; then
    append_log "ERROR" "prompt file not found for ${agent_id}: ${prompt_file}"
    return 1
  fi

  local message
  message="$(printf '%s\n' \
    "你正在执行觅诗项目自动协作流水线中的一次标准轮次。" \
    "" \
    "时间：${ts}" \
    "工作区：${ROOT_DIR}" \
    "" \
    "请先完整阅读：" \
    "1) ${prompt_file}" \
    "2) ${ROOT_DIR}/docs/agents/shared-workspace.md" \
    "3) ${ROOT_DIR}/collab/handoff/dependency-queue.md" \
    "4) ${ROOT_DIR}/collab/handoff/daily-sync.md" \
    "" \
    "本轮目标：" \
    "${mission}" \
    "" \
    "执行要求：" \
    "- 严格按你的角色职责输出到对应 collab 目录。" \
    "- 本轮若有任务进展，必须在域文档末尾追加 Completion Sync 块。" \
    "- 如果需要跨角色协调，在你产出的文档末尾新增 Scheduling Request 区块。" \
    "- 除 coordinator-agent 外，不得直接编辑 collab/handoff/*。" \
    "- 如果遇到阻塞，请给出明确 blocker、owner、next_check_at。" \
    "- 输出应可被下一角色直接消费，避免空泛描述。")"

  append_log "INFO" "start ${agent_id}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    append_log "INFO" "dry-run: skip openclaw call for ${agent_id}"
    return 0
  fi
  set +e
  "${OPENCLAW_BIN}" agent ${OPENCLAW_MODE} --agent "${agent_id}" --timeout "${TIMEOUT_SECONDS}" --message "${message}" --json >>"${RUN_LOG}" 2>&1
  local code=$?
  set -e
  if [[ ${code} -ne 0 ]]; then
    append_log "ERROR" "${agent_id} failed with code ${code}"
    return ${code}
  fi
  append_log "INFO" "done ${agent_id}"
}

run_cycle() {
  append_log "INFO" "==== cycle start ===="
  run_agent_turn "coordinator-agent" "根据当前 dependency-queue 与 daily-sync，更新本轮调度顺序，分配任务 owner/approver/state，并在 daily-sync 追加一条 cycle-start 记录；同时声明将消费本轮 Completion Sync。"

  run_agent_turn "pm-agent" "处理需求澄清与验收标准变更，若有范围/优先级调整，提交 Scheduling Request。"
  run_agent_turn "arch-agent" "评审本轮技术变更与 API/数据影响，必要时更新 ADR 和契约，并提交 Scheduling Request。"
  run_agent_turn "backend-agent" "执行后端任务（服务/数据/联调），提交证据链接与阻塞信息。"
  run_agent_turn "frontend-agent" "执行前端任务（页面/状态/联调），提交证据链接与阻塞信息。"
  run_agent_turn "app-agent" "执行 App 端任务（定位/语音/动画/打卡），提交证据链接与阻塞信息。"

  run_agent_turn "coordinator-agent" "汇总五角色产出，优先消费各域文档的 Completion Sync 与 Scheduling Request，更新 dependency-queue 状态（todo/in_progress/blocked/review/done/cancelled），并在 daily-sync 追加 cycle-end 记录（含 accepted/rejected 处理结果）。"
  append_log "INFO" "==== cycle end ===="
}

main() {
  require_cmd "${OPENCLAW_BIN}"

  if [[ ! -f "${ROOT_DIR}/docs/agents/shared-workspace.md" ]]; then
    append_log "ERROR" "missing docs/agents/shared-workspace.md"
    exit 1
  fi

  run_cycle
}

main "$@"
