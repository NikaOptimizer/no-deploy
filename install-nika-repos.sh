#!/usr/bin/env bash
set -euo pipefail

: "${GIT_TRANSPORT:=https}"
: "${GITHUB_ORG:=NikaOptimizer}"
: "${GIT_REF:=main}"
: "${NIKA_REPOS:=no-logging no-calculator fisher data-manager strategist backend frontend}"
: "${VIRTUAL_ENV:=/opt/nika/venv}"

SRC_DIR='/opt/nika/src'
mkdir -p "${SRC_DIR}"

repo_url() {
    local repo="$1"
    case "${GIT_TRANSPORT}" in
        https)
            printf 'https://github.com/%s/%s.git' "${GITHUB_ORG}" "${repo}"
            ;;
        ssh)
            printf 'git@github.com:%s/%s.git' "${GITHUB_ORG}" "${repo}"
            ;;
        *)
            echo "Unsupported GIT_TRANSPORT: ${GIT_TRANSPORT}. Use 'https' or 'ssh'." >&2
            exit 2
            ;;
    esac
}

if [ ! -x "${VIRTUAL_ENV}/bin/python" ]; then
    echo "Virtual environment not found at ${VIRTUAL_ENV}" >&2
    exit 2
fi

export PATH="${VIRTUAL_ENV}/bin:${PATH}"

python -m pip install --upgrade pip setuptools wheel packaging

for repo in ${NIKA_REPOS}; do
    url="$(repo_url "${repo}")"
    target="${SRC_DIR}/${repo}"

    echo "==> Cloning ${repo} from ${url}"
    rm -rf "${target}"
    git clone --depth 1 --branch "${GIT_REF}" "${url}" "${target}"

    if [ -f "${target}/pyproject.toml" ] || [ -f "${target}/setup.py" ]; then
        echo "==> Installing Python package ${repo}"
        python -m pip install --no-cache-dir "${target}"
    else
        echo "==> ${repo} has no pyproject.toml or setup.py; cloned but not pip-installable yet"
    fi

    if [ "${repo}" = 'frontend' ] && [ -f "${target}/client/package.json" ]; then
        echo '==> Installing frontend dependencies'
        (cd "${target}" && bun install)
        (cd "${target}/client" && bun install)
    fi

done

echo '==> Installed Python packages:'
python -m pip list
