# syntax=docker/dockerfile:1.7

# Nika runtime image.
# Repositories are cloned directly from GitHub during the image build and then
# installed as Python packages in dependency order. No host workspace mount is
# required at runtime.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VIRTUAL_ENV=/opt/nika/venv
ENV PATH="/opt/nika/venv/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Choose one clone transport:
#   https -> https://github.com/NikaOptimizer/<repo>.git
#   ssh   -> git@github.com:NikaOptimizer/<repo>.git, requires BuildKit --ssh
ARG GIT_TRANSPORT=https
ARG GITHUB_ORG=NikaOptimizer
ARG GIT_REF=main

# Dependency order. Keep this order unless package dependencies change.
# no-logging is cloned first because it is intended to become a shared package.
# At the time this Dockerfile was written it has no setup.py/pyproject.toml, so
# the installer script clones it and reports that it is not yet installable.
ARG NIKA_REPOS="no-logging no-calculator fisher data-manager strategist backend frontend"

RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \
      openssh-client \
      python3 \
      python3-dev \
      python3-pip \
      python3-venv \
      unzip \
      build-essential \
 && rm -rf /var/lib/apt/lists/*

ENV BUN_INSTALL=/opt/bun
ENV PATH="/opt/bun/bin:/opt/nika/venv/bin:${PATH}"

RUN curl -fsSL https://bun.sh/install | bash \
 && chmod -R a+rx /opt/bun

RUN mkdir -p /root/.ssh \
 && ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN python3 -m venv "${VIRTUAL_ENV}" \
 && python -m pip install --upgrade pip setuptools wheel packaging

COPY requirements.txt /tmp/requirements.txt
RUN python -m pip install --no-cache-dir -r /tmp/requirements.txt \
 && rm /tmp/requirements.txt

RUN useradd -m -s /bin/bash nika \
 && mkdir -p /opt/nika/src \
 && chown -R nika:nika /opt/nika /home/nika

COPY install-nika-repos.sh /usr/local/bin/install-nika-repos
RUN chmod +x /usr/local/bin/install-nika-repos

COPY start-nika.sh /usr/local/bin/start-nika
RUN chmod +x /usr/local/bin/start-nika

# The ssh mount is optional for HTTPS builds and required only when
# GIT_TRANSPORT=ssh. Example:
#   DOCKER_BUILDKIT=1 docker build --ssh default --build-arg GIT_TRANSPORT=ssh .
RUN --mount=type=ssh,required=false install-nika-repos
RUN chown -R nika:nika /opt/nika /home/nika

WORKDIR /home/nika
USER nika

CMD ["/usr/local/bin/start-nika"]
