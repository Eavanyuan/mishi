#!/usr/bin/env bash
set -euo pipefail

BACKEND_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_URL="${BASE_URL:-http://127.0.0.1:8080/v1}"

compose() {
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  else
    return 127
  fi
}

for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[e2e-web] missing dependency: $cmd"
    exit 1
  fi
done

timestamp="$(date +%s)"
email="web_e2e_${timestamp}@mishi.app"
password="123456"
device_id="web-e2e-${timestamp}"

backend_started_by_script=0
backend_pid=""

cleanup() {
  if [[ "$backend_started_by_script" -eq 1 && -n "$backend_pid" ]]; then
    kill "$backend_pid" >/dev/null 2>&1 || true
    wait "$backend_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

wait_for_health() {
  local retries=30
  local i
  for i in $(seq 1 "$retries"); do
    if curl -fsS "http://127.0.0.1:8080/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

wait_for_postgres() {
  local retries=60
  local i
  for i in $(seq 1 "$retries"); do
    if compose -f "$BACKEND_ROOT/docker-compose.yml" exec -T postgres pg_isready -U mishi -d mishi >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

wait_for_redis() {
  local retries=60
  local i
  for i in $(seq 1 "$retries"); do
    if compose -f "$BACKEND_ROOT/docker-compose.yml" exec -T redis redis-cli ping >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

if [[ -f "$BACKEND_ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$BACKEND_ROOT/.env"
  set +a
fi

if ! curl -fsS "http://127.0.0.1:8080/health" >/dev/null 2>&1; then
  echo "[e2e-web] backend not running, bootstrapping dependencies..."
  (cd "$BACKEND_ROOT" && compose -f docker-compose.yml up -d postgres redis >/dev/null)

  echo "[e2e-web] waiting for postgres..."
  if ! wait_for_postgres; then
    echo "[e2e-web] postgres did not become ready in time"
    exit 1
  fi

  echo "[e2e-web] waiting for redis..."
  if ! wait_for_redis; then
    echo "[e2e-web] redis did not become ready in time"
    exit 1
  fi

  echo "[e2e-web] starting backend locally..."
  (
    cd "$BACKEND_ROOT"
    MISHI_DATABASE_HOST="${MISHI_DATABASE_HOST:-127.0.0.1}" \
    MISHI_REDIS_HOST="${MISHI_REDIS_HOST:-127.0.0.1}" \
    go run cmd/server/main.go
  ) >/tmp/mishi-e2e-backend.log 2>&1 &
  backend_pid="$!"
  backend_started_by_script=1

  if ! wait_for_health; then
    echo "[e2e-web] backend did not become healthy in time"
    echo "[e2e-web] backend log tail:"
    tail -n 60 /tmp/mishi-e2e-backend.log || true
    exit 1
  fi
fi

health="$(curl -sS "http://127.0.0.1:8080/health")"
register="$(curl -sS -X POST "$BASE_URL/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$email\",\"password\":\"$password\",\"username\":\"web_e2e\"}")"
login="$(curl -sS -X POST "$BASE_URL/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$email\",\"password\":\"$password\",\"device_id\":\"$device_id\"}")"

token="$(echo "$login" | jq -r '.data.access_token')"
user_id="$(echo "$login" | jq -r '.data.user.id')"
refresh_token="$(echo "$login" | jq -r '.data.refresh_token')"

recommend="$(curl -sS "$BASE_URL/poems/recommend?lat=30.547&lon=114.312&limit=1")"
poem_id="$(echo "$recommend" | jq -r '.data.poems[0].poem_id')"
detail="$(curl -sS "$BASE_URL/poems/$poem_id")"
nearby="$(curl -sS "$BASE_URL/geo/nearby?lat=30.547&lon=114.312&limit=1")"
poi_id="$(echo "$nearby" | jq -r '.data.pois[0].poi_id')"
poi_lat="$(echo "$nearby" | jq -r '.data.pois[0].location.lat')"
poi_lon="$(echo "$nearby" | jq -r '.data.pois[0].location.lon')"

ai_create="$(curl -sS -X POST "$BASE_URL/ai/jobs" \
  -H "Authorization: Bearer $token" \
  -H "X-Device-Id: $device_id" \
  -H 'Content-Type: application/json' \
  -d "{\"job_type\":\"interpretation\",\"poem_id\":$poem_id,\"style\":\"modern\"}")"
job_id="$(echo "$ai_create" | jq -r '.data.job_id')"

ai_job=""
for _ in $(seq 1 20); do
  ai_job="$(curl -sS "$BASE_URL/ai/jobs/$job_id" \
    -H "Authorization: Bearer $token" \
    -H "X-Device-Id: $device_id")"
  ai_status="$(echo "$ai_job" | jq -r '.data.status')"
  if [[ "$ai_status" == "success" || "$ai_status" == "succeeded" || "$ai_status" == "failed" ]]; then
    break
  fi
  sleep 1
done

checkin="$(curl -sS -X POST "$BASE_URL/checkins/" \
  -H "Authorization: Bearer $token" \
  -H "X-Device-Id: $device_id" \
  -H 'Content-Type: application/json' \
  -d "{\"poi_id\":$poi_id,\"poem_id\":$poem_id,\"lat\":$poi_lat,\"lon\":$poi_lon,\"gps_accuracy\":10,\"device_info\":{\"device_id\":\"$device_id\",\"device_model\":\"web\",\"os_version\":\"macOS\",\"is_emulator\":false,\"is_rooted\":false}}")"
history="$(curl -sS "$BASE_URL/checkins/history?limit=5" \
  -H "Authorization: Bearer $token" \
  -H "X-Device-Id: $device_id")"
profile="$(curl -sS "$BASE_URL/profile/$user_id" \
  -H "Authorization: Bearer $token" \
  -H "X-Device-Id: $device_id")"
refresh="$(curl -sS -X POST "$BASE_URL/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refresh_token\":\"$refresh_token\"}")"

echo "HEALTH"
echo "$health" | jq '{code, status: .data.status}'
echo "REGISTER"
echo "$register" | jq '{code, user_id: .data.user.id}'
echo "LOGIN"
echo "$login" | jq '{code, user_id: .data.user.id}'
echo "RECOMMEND"
echo "$recommend" | jq '{code, count: (.data.poems|length), poem_id: .data.poems[0].poem_id, title: .data.poems[0].title}'
echo "DETAIL"
echo "$detail" | jq '{code, poem_id: .data.poem_id, title: .data.title}'
echo "AI_JOB"
echo "$ai_job" | jq '{code, status: .data.status, has_text: (.data.output.text != null)}'
echo "CHECKIN"
echo "$checkin" | jq '{code, message, checkin_id: .data.checkin_id, poi: .data.poi_name}'
echo "HISTORY"
echo "$history" | jq '{code, total: .data.total, latest: .data.checkins[0] | {checkin_id, poi_name}}'
echo "PROFILE"
echo "$profile" | jq '{code, user: .data.user | {id, nickname, checkin_count}}'
echo "REFRESH"
echo "$refresh" | jq '{code, has_access_token: (.data.access_token != null)}'
