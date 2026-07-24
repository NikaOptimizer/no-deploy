#!/usr/bin/env bash
set -euo pipefail

: "${NIKA_SRC_DIR:=/opt/nika/src}"
: "${NIKA_LOG_DIR:=/home/nika/logs}"
: "${NIKA_BACKEND_HOST:=0.0.0.0}"
: "${NIKA_BACKEND_PORT:=8000}"
: "${NIKA_FRONTEND_HOST:=0.0.0.0}"
: "${NIKA_FRONTEND_PORT:=5173}"
: "${NIKA_START_BACKEND:=1}"
: "${NIKA_START_FRONTEND:=1}"

mkdir -p "${NIKA_LOG_DIR}"

pids=()

start_backend() {
    local backend_dir="${NIKA_SRC_DIR}/backend"

    if [ "${NIKA_START_BACKEND}" != '1' ]; then
        echo 'Backend startup disabled by NIKA_START_BACKEND.'
        return 0
    fi

    if [ ! -f "${backend_dir}/manage.py" ]; then
        echo "Backend repo not found at ${backend_dir}; skipping backend startup."
        return 0
    fi

    echo "Starting Django backend on ${NIKA_BACKEND_HOST}:${NIKA_BACKEND_PORT}"
    (
        cd "${backend_dir}"
        python manage.py runserver "${NIKA_BACKEND_HOST}:${NIKA_BACKEND_PORT}"
    ) >"${NIKA_LOG_DIR}/backend.log" 2>&1 &
    pids+=("$!")
}

start_frontend() {
    local frontend_dir="${NIKA_SRC_DIR}/frontend"
    local app_dir="${frontend_dir}"

    if [ "${NIKA_START_FRONTEND}" != '1' ]; then
        echo 'Frontend startup disabled by NIKA_START_FRONTEND.'
        return 0
    fi

    if [ ! -f "${app_dir}/package.json" ]; then
        if [ -f "${frontend_dir}/client/package.json" ]; then
            app_dir="${frontend_dir}/client"
        else
            echo "Frontend app not found at ${frontend_dir}; skipping frontend startup."
            return 0
        fi
    fi

    echo "Starting Vite frontend on ${NIKA_FRONTEND_HOST}:${NIKA_FRONTEND_PORT}"
    (
        cd "${app_dir}"
        bun run dev --host "${NIKA_FRONTEND_HOST}" --port "${NIKA_FRONTEND_PORT}"
    ) >"${NIKA_LOG_DIR}/frontend.log" 2>&1 &
    pids+=("$!")
}

shutdown() {
    echo 'Stopping Nika services...'
    for pid in "${pids[@]}"; do
        if kill -0 "${pid}" 2>/dev/null; then
            kill "${pid}" 2>/dev/null || true
        fi
    done
}

trap shutdown INT TERM

start_backend
start_frontend

if [ "${#pids[@]}" -eq 0 ]; then
    echo 'No Nika services were started. Keeping container alive for inspection.'
    tail -f /dev/null
fi

echo 'Nika services started.'
echo "Backend log: ${NIKA_LOG_DIR}/backend.log"
echo "Frontend log: ${NIKA_LOG_DIR}/frontend.log"

wait -n "${pids[@]}"
exit_code="$?"
shutdown
exit "${exit_code}"
