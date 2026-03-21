#!/usr/bin/env bash
# Shared paths and defaults for kube9-localcluster scripts.
# Caller must set SCRIPT_DIR and REPO_ROOT before sourcing.

: "${REPO_ROOT:?REPO_ROOT must be set}" "${SCRIPT_DIR:?SCRIPT_DIR must be set}"

export MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-kube9-demo}"
PROFILE="${MINIKUBE_PROFILE}"

KUBECONFIG_DIR="${KUBECONFIG_DIR:-${REPO_ROOT}/out}"
KUBECONFIG_FILE="${KUBECONFIG_DIR}/kubeconfig"
export SCENARIOS_DIR="${REPO_ROOT}/scenarios"

# Sibling checkout of kube9-operator (override with KUBE9_OPERATOR_ROOT or OPERATOR_CHART_PATH)
KUBE9_OPERATOR_ROOT="${KUBE9_OPERATOR_ROOT:-${REPO_ROOT}/../kube9-operator}"
OPERATOR_CHART_PATH="${OPERATOR_CHART_PATH:-${KUBE9_OPERATOR_ROOT}/charts/kube9-operator}"
