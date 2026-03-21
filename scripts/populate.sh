#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <scenario-name>"
    echo ""
    echo "Available scenarios:"
    echo "  with-operator    - kube9-operator (Helm) + demo workloads"
    echo "  without-operator - No operator"
    echo "  healthy          - Healthy workloads"
    echo "  degraded         - Error-state workloads"
    echo ""
    echo "Example:"
    echo "  $0 with-operator"
    exit 1
fi

SCENARIO_NAME="$1"
SCENARIO_FILE="${SCENARIOS_DIR}/${SCENARIO_NAME}.yaml"

if ! command -v minikube &> /dev/null; then
    echo "Error: Minikube not found."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if [ "${SCENARIO_NAME}" = "with-operator" ]; then
    if ! command -v helm &> /dev/null; then
        echo "Error: Helm is required for with-operator."
        exit 1
    fi
fi

if [ "${SCENARIO_NAME}" = "with-operator" ]; then
    WORKLOADS_FILE="${SCENARIOS_DIR}/with-operator-workloads.yaml"
    if [ ! -f "${WORKLOADS_FILE}" ]; then
        echo "Error: Workloads file not found: ${WORKLOADS_FILE}"
        exit 1
    fi
elif [ ! -f "${SCENARIO_FILE}" ]; then
    echo "Error: Scenario '${SCENARIO_NAME}' not found: ${SCENARIO_FILE}"
    echo ""
    echo "Available scenarios:"
    if [ -d "${SCENARIOS_DIR}" ]; then
        for scenario in "${SCENARIOS_DIR}"/*.yaml; do
            if [ -f "${scenario}" ]; then
                base=$(basename "${scenario}" .yaml)
                if [ "${base}" != "with-operator-workloads" ]; then
                    echo "  - ${base}"
                fi
            fi
        done
    fi
    exit 1
fi

if ! minikube status --profile="${PROFILE}" &> /dev/null; then
    echo "Error: Cluster is not running. Start it first:"
    echo "  ${REPO_ROOT}/scripts/start.sh"
    exit 1
fi

if [ ! -f "${KUBECONFIG_FILE}" ]; then
    echo "Error: Kubeconfig not found: ${KUBECONFIG_FILE}"
    echo "Run ${REPO_ROOT}/scripts/start.sh to create the cluster and export kubeconfig."
    exit 1
fi

export KUBECONFIG="${KUBECONFIG_FILE}"
RESOURCE_COUNT=$(kubectl get all --all-namespaces --ignore-not-found 2>/dev/null | grep -v "kube-system" | grep -v "^NAME" | wc -l | tr -d ' ')

if [ "${RESOURCE_COUNT}" -gt 0 ]; then
    echo "Warning: Cluster already has user workloads"
    echo ""
    read -p "Delete existing resources before deploying scenario? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleaning up..."
        if command -v helm &> /dev/null; then
            HELM_RELEASES=$(helm list --all-namespaces -q 2>/dev/null || true)
            if [ -n "${HELM_RELEASES}" ]; then
                while IFS= read -r release; do
                    if [ -n "${release}" ]; then
                        RELEASE_NAMESPACE=$(helm list --all-namespaces -f "^${release}$" -o json 2>/dev/null | jq -r '.[0].namespace' 2>/dev/null || echo "")
                        if [ -n "${RELEASE_NAMESPACE}" ]; then
                            helm uninstall "${release}" --namespace "${RELEASE_NAMESPACE}" --wait 2>/dev/null || true
                        fi
                    fi
                done <<< "${HELM_RELEASES}"
            fi
        fi
        if command -v jq &> /dev/null; then
            kubectl get namespaces -o json 2>/dev/null | \
                jq -r '.items[] | select(.metadata.name | IN("kube-system", "kube-public", "kube-node-lease", "default") | not) | .metadata.name' | \
                while read -r ns; do
                    if [ -n "${ns}" ]; then
                        kubectl delete namespace "${ns}" --wait=false 2>/dev/null || true
                    fi
                done
        else
            kubectl get namespaces -o name 2>/dev/null | \
                grep -v "namespace/kube-system" | \
                grep -v "namespace/kube-public" | \
                grep -v "namespace/kube-node-lease" | \
                grep -v "namespace/default" | \
                sed 's/namespace\///' | \
                while read -r ns; do
                    if [ -n "${ns}" ]; then
                        kubectl delete namespace "${ns}" --wait=false 2>/dev/null || true
                    fi
                done
        fi
        kubectl delete all --all -n default --wait=false 2>/dev/null || true
        echo "Waiting for cleanup..."
        sleep 5
    fi
fi

echo "Deploying scenario: ${SCENARIO_NAME}..."

if [ "${SCENARIO_NAME}" = "with-operator" ]; then
    if [ ! -d "${OPERATOR_CHART_PATH}" ]; then
        echo "Error: kube9-operator chart not found at: ${OPERATOR_CHART_PATH}"
        echo "Clone kube9-operator next to this repo or set KUBE9_OPERATOR_ROOT or OPERATOR_CHART_PATH."
        exit 1
    fi

    echo "Installing kube9-operator via Helm (chart: ${OPERATOR_CHART_PATH})..."
    helm install kube9-operator "${OPERATOR_CHART_PATH}" \
        --namespace kube9-system \
        --create-namespace \
        --wait \
        --timeout 5m

    echo ""
    echo "✓ kube9-operator installed"
    echo ""
    echo "Applying demo workloads..."
    kubectl apply -f "${WORKLOADS_FILE}"
    sleep 3
else
    kubectl apply -f "${SCENARIO_FILE}"
    sleep 3
fi

echo ""
echo "✓ Scenario '${SCENARIO_NAME}' deployed"
echo ""
kubectl get all --all-namespaces 2>/dev/null | grep -v "kube-system" || true
echo ""
echo "Point tools at this cluster:"
echo "  export KUBECONFIG=${KUBECONFIG_FILE}"
