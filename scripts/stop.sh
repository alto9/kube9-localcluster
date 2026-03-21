#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

if ! command -v minikube &> /dev/null; then
    echo "Error: Minikube not found. Please install Minikube:"
    echo "  macOS: brew install minikube"
    echo "  Linux: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

if ! minikube status --profile="${PROFILE}" &> /dev/null; then
    echo "Cluster is not running (profile: ${PROFILE})"
    echo ""
    echo "To start:"
    echo "  ${REPO_ROOT}/scripts/start.sh"
    exit 0
fi

echo "Stopping cluster (profile: ${PROFILE})..."
minikube stop --profile="${PROFILE}"

echo ""
echo "✓ Cluster stopped (state preserved on disk)"
echo ""
echo "To start again:"
echo "  ${REPO_ROOT}/scripts/start.sh"
