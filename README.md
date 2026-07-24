# no-deploy

`no-deploy` builds a Nika runtime container from `ubuntu:24.04`.

The image does not mount the host workspace. During `docker build`, it clones the Nika repositories directly from GitHub and installs the Python repositories into a virtual environment in dependency order.

## What gets installed

Default repository order:

1. `no-logging`
2. `no-calculator`
3. `fisher`
4. `data-manager`
5. `strategist`
6. `backend`
7. `frontend`

This order keeps lower-level shared packages ahead of packages that import or depend on them.

The Python repositories are installed with pip when they expose `setup.py` or `pyproject.toml`. The frontend repository is installed with Bun so the Vite dev server can start with the container.

## Build with public HTTPS clones

```bash
./init.sh
```

Equivalent direct build command:

```bash
docker build \
  --build-arg GIT_TRANSPORT=https \
  --build-arg GITHUB_ORG=NikaOptimizer \
  --build-arg GIT_REF=main \
  -t nika:latest .
```

## Build with SSH clones

Use this when the repositories are private or when GitHub requires SSH access.

```bash
GIT_TRANSPORT=ssh ./init.sh
```

Equivalent direct build command:

```bash
DOCKER_BUILDKIT=1 docker build \
  --ssh default \
  --build-arg GIT_TRANSPORT=ssh \
  --build-arg GITHUB_ORG=NikaOptimizer \
  --build-arg GIT_REF=main \
  -t nika:latest .
```

The SSH mode forwards your local SSH agent into the build. It does not copy your SSH keys into the image.

## Customize the repository list

```bash
NIKA_REPOS='no-logging no-calculator fisher data-manager strategist backend frontend' ./init.sh
```

The default startup expects both `backend` and `frontend` repositories to be available in the configured GitHub organization/ref. If a repository has not been published yet, temporarily remove it from `NIKA_REPOS` while building.

## Customize the Git ref

Install from another branch/tag/commit:

```bash
GIT_REF=main ./init.sh
```

## Start a shell

After `init.sh` finishes:

```bash
docker exec -it nika bash
```

The container starts the Django backend and Vite frontend automatically through `start-nika.sh`:

```text
Frontend: http://127.0.0.1:5173
Backend:  http://127.0.0.1:8000
```

Service logs are written inside the container:

```bash
docker exec nika tail -f /home/nika/logs/backend.log
docker exec nika tail -f /home/nika/logs/frontend.log
```

Startup can be customized with environment variables:

```bash
NIKA_START_BACKEND=0 ./init.sh      # skip backend startup
NIKA_START_FRONTEND=0 ./init.sh     # skip frontend startup
```


## Files

- `Dockerfile` creates the Ubuntu-based runtime image.
- `install-nika-repos.sh` clones and installs repositories during image build.
- `start-nika.sh` starts the backend and frontend when the container starts.
- `init.sh` builds the image and starts a container.
- `requirements.txt` holds base Python packaging tools only; repo dependencies come from the repos themselves.
