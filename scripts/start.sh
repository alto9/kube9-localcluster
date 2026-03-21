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

if minikube status --profile="${PROFILE}" &> /dev/null; then
    echo "Local cluster is already running (profile: ${PROFILE})"
    echo "Kubeconfig: ${KUBECONFIG_FILE}"
    echo ""
    echo "To populate with a scenario, run:"
    echo "  ${REPO_ROOT}/scripts/populate.sh <scenario-name>"
    exit 0
fi

mkdir -p "${KUBECONFIG_DIR}"

echo "Starting local cluster (profile: ${PROFILE})..."
minikube start \
    --profile="${PROFILE}" \
    --cpus=2 \
    --memory=4096 \
    --driver=docker \
    --kubernetes-version=stable

echo "Exporting isolated kubeconfig..."
MINIKUBE_KUBECONFIG=$(minikube kubectl --profile="${PROFILE}" -- config view --flatten --minify)
echo "${MINIKUBE_KUBECONFIG}" > "${KUBECONFIG_FILE}"

echo ""
echo "✓ Cluster started successfully"
echo "✓ Kubeconfig: ${KUBECONFIG_FILE}"
echo ""
echo "Export for tools that read KUBECONFIG:"
echo "  export KUBECONFIG=${KUBECONFIG_FILE}"
echo ""
echo "Available scenarios:"
echo "  - with-operator    : kube9-operator (Helm) + demo workloads"
echo "  - without-operator : No operator (free-tier style)"
echo "  - healthy          : Workloads in healthy state"
echo "  - degraded         : Workloads in error states"
echo ""
echo "Populate:"
echo "  ${REPO_ROOT}/scripts/populate.sh <scenario-name>"
