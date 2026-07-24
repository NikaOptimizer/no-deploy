#!/usr/bin/env bash
set -euo pipefail

image_name="${NIKA_IMAGE_NAME:-nika:latest}"
container_name="${NIKA_CONTAINER_NAME:-nika}"
git_transport="${GIT_TRANSPORT:-https}"
github_org="${GITHUB_ORG:-NikaOptimizer}"
git_ref="${GIT_REF:-main}"
repos="${NIKA_REPOS:-no-logging no-calculator fisher data-manager strategist backend frontend}"
start_backend="${NIKA_START_BACKEND:-1}"
start_frontend="${NIKA_START_FRONTEND:-1}"
backend_port="${NIKA_BACKEND_PORT:-8000}"
frontend_port="${NIKA_FRONTEND_PORT:-5173}"

script_dir="$(cd "$(dirname "$0")" && pwd)"
cd "${script_dir}"

build_args=(
    --build-arg "GIT_TRANSPORT=${git_transport}"
    --build-arg "GITHUB_ORG=${github_org}"
    --build-arg "GIT_REF=${git_ref}"
    --build-arg "NIKA_REPOS=${repos}"
    -t "${image_name}"
)

if [ "${git_transport}" = 'ssh' ]; then
    export DOCKER_BUILDKIT=1
    build_args=(--ssh default "${build_args[@]}")
fi

echo "Building ${image_name} from GitHub repos: ${repos}"
docker build "${build_args[@]}" .

if docker ps -a --format '{{.Names}}' | grep -qx "${container_name}"; then
    echo "Removing existing container ${container_name}"
    docker rm -f "${container_name}" >/dev/null
fi

echo "Starting ${container_name}"
docker run \
    --name "${container_name}" \
    --hostname "${container_name}" \
    -e "NIKA_START_BACKEND=${start_backend}" \
    -e "NIKA_START_FRONTEND=${start_frontend}" \
    -e "NIKA_BACKEND_PORT=${backend_port}" \
    -e "NIKA_FRONTEND_PORT=${frontend_port}" \
    --network host \
    -it -d "${image_name}"

echo "Container ${container_name} is ready."
echo "Frontend: http://127.0.0.1:${frontend_port}"
echo "Backend:  http://127.0.0.1:${backend_port}"
echo "Logs: docker exec ${container_name} ls -l /home/nika/logs"
echo "Open a shell with: docker exec -it ${container_name} bash"
