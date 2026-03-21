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

echo "WARNING: This will DELETE the Minikube cluster and its data."
echo "Profile: ${PROFILE}"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Reset cancelled"
    exit 0
fi

if minikube status --profile="${PROFILE}" &> /dev/null; then
    echo "Deleting cluster..."
    minikube delete --profile="${PROFILE}"
fi

rm -f "${KUBECONFIG_FILE}"

echo "Creating fresh cluster..."
minikube start \
    --profile="${PROFILE}" \
    --cpus=2 \
    --memory=4096 \
    --driver=docker \
    --kubernetes-version=stable

mkdir -p "${KUBECONFIG_DIR}"
echo "Exporting isolated kubeconfig..."
MINIKUBE_KUBECONFIG=$(minikube kubectl --profile="${PROFILE}" -- config view --flatten --minify)
echo "${MINIKUBE_KUBECONFIG}" > "${KUBECONFIG_FILE}"

echo ""
echo "✓ Cluster reset complete"
echo "✓ Kubeconfig: ${KUBECONFIG_FILE}"
echo ""
echo "Populate:"
echo "  ${REPO_ROOT}/scripts/populate.sh <scenario-name>"
