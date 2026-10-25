#!/bin/bash
# Run a build command inside the toolchain builder container.
#
# The job-level `container:` key cannot be used for a CentOS 7 build because
# the runner injects node 24, which needs glibc >= 2.27 (CentOS 7 provides
# 2.17). JS actions therefore stay on the runner; only configure/make are
# wrapped here so they see the old glibc and produce compatible binaries.
#
# The workspace is mounted at its runner path so that paths recorded by
# configure (and ccache's CCACHE_BASEDIR) stay valid on the runner afterwards.
#
# The container runs as the runner's uid/gid so it can write the bind-mounted
# workspace.
#
# Usage: IMAGE=<image> in-container.sh '<shell command>'
set -euo pipefail

: "${IMAGE:?IMAGE must be set}"
: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}"

exec docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e CCACHE_DIR="${CCACHE_DIR:-/mnt/ccache}" \
    -e CCACHE_BASEDIR="${CCACHE_BASEDIR:-${GITHUB_WORKSPACE}}" \
    -e CCACHE_COMPILERCHECK="${CCACHE_COMPILERCHECK:-content}" \
    -e CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-2G}" \
    -v "${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE}" \
    -v /mnt:/mnt \
    -w "${GITHUB_WORKSPACE}" \
    "${IMAGE}" \
    bash -lc "$*"
