# kube9-minikube

Scripts and YAML scenarios for a **dedicated local Minikube cluster** used when developing [kube9-vscode](https://github.com/alto9/kube9-vscode) and [kube9-operator](https://github.com/alto9/kube9-operator). This repo is the **only** place that creates or populates that cluster; the extension and operator repos do not ship cluster bring-up scripts.

## What you get

- Minikube profile (default `kube9-demo`) isolated from your main `~/.kube/config`
- Exported kubeconfig at **`out/kubeconfig`** (set `KUBECONFIG` to this file)
- Scenarios: `with-operator`, `without-operator`, `healthy`, `degraded`

## Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) (Docker driver used by default)
- `kubectl`
- `helm` (only for `with-operator` scenario)
- Optional: sibling clone of **kube9-operator** for the `with-operator` scenario (see below)

## Quick start

From this repository root:

```bash
./scripts/start.sh
export KUBECONFIG="$PWD/out/kubeconfig"
./scripts/populate.sh with-operator   # or another scenario
```

Stop or fully reset:

```bash
./scripts/stop.sh
./scripts/reset.sh   # deletes cluster data, recreates cluster
```

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `MINIKUBE_PROFILE` | `kube9-demo` | Minikube profile name |
| `KUBECONFIG_DIR` | `<repo>/out` | Directory containing generated `kubeconfig` |
| `KUBE9_OPERATOR_ROOT` | `<repo>/../kube9-operator` | Root of kube9-operator checkout |
| `OPERATOR_CHART_PATH` | `$KUBE9_OPERATOR_ROOT/charts/kube9-operator` | Helm chart for `with-operator` |

If `kube9-operator` is not beside this repo, set `KUBE9_OPERATOR_ROOT` or `OPERATOR_CHART_PATH` before running `./scripts/populate.sh with-operator`.

## Scenarios

| Name | Description |
|------|-------------|
| `with-operator` | `helm install` of kube9-operator chart + demo workloads (`scenarios/with-operator-workloads.yaml`) |
| `without-operator` | Workloads only, no operator |
| `healthy` | Workloads in healthy state |
| `degraded` | Workloads in error states for UI testing |

## Developing kube9-vscode

1. Run `./scripts/start.sh` and `./scripts/populate.sh` as needed.
2. `export KUBECONFIG=<path-to-this-repo>/out/kubeconfig`
3. In the kube9-vscode repo, use the **Extension (Demo Cluster)** launch configuration (it sets `KUBECONFIG` to the localcluster output path when repos are laid out side by side).

## Developing kube9-operator

Use a cluster from this repo (`./scripts/start.sh`), with `KUBECONFIG` pointing at `out/kubeconfig`.

There are **two** complementary workflows:

1. **Scenario / extension demos** — `./scripts/populate.sh with-operator` installs the chart from disk (typically published-chart parity) plus bundled demo workloads. Use this when validating the VS Code extension against a predictable cluster.
2. **Local operator image iteration** — from the **kube9-operator** repo, use `npm run deploy:minikube` (or equivalent) to build a **local** image, load it into Minikube, and upgrade the Helm release. Use this when changing operator code.

Set `MINIKUBE_PROFILE` to the same value in both repos (default `kube9-demo`) so `minikube image load` targets the correct node.

## Scripts

| Script | Role |
|--------|------|
| `scripts/start.sh` | Create/start cluster, write `out/kubeconfig` |
| `scripts/stop.sh` | Stop Minikube (keeps disk state) |
| `scripts/reset.sh` | Delete cluster, recreate, re-export kubeconfig |
| `scripts/populate.sh` | Apply a scenario |

## npm (optional)

```bash
npm run cluster:start
npm run cluster:stop
npm run cluster:populate -- with-operator
```

See `package.json` for definitions.
