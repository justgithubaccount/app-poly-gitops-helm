# Chat API Helm Chart

Helm chart for deploying
[app-poly-gitops-fastapi](https://github.com/justgithubaccount/app-poly-gitops-fastapi)
to Kubernetes. The chart packages the Deployment, Service, optional Ingress,
ServiceAccount, and optional external-service wiring.

## Overview

- Chart version: `0.4.1`
- Application version and default image tag: `1.1.2`
- Default service: `ClusterIP` on port 80
- Default persistence: application-managed SQLite
- Optional dependencies: OpenRouter secret and PostgreSQL connection secret

No secret is required for rendering the chart or starting the health endpoint.
Real model requests require a secret selected with
`openrouterSecretRefName`. PostgreSQL can be supplied through
`postgresSecretRefName` or explicit `extraEnv` entries.

## Getting started

Requirements: Helm 3 and access to a Kubernetes cluster for installation.

~~~bash
helm lint .
helm template chat-api . --namespace chat-api
~~~

To install the defaults:

~~~bash
helm upgrade --install chat-api . \
  --namespace chat-api \
  --create-namespace
~~~

For a real provider key, create the Secret outside the chart and reference it:

~~~bash
kubectl -n chat-api create secret generic chat-openrouter \
  --from-literal=OPENROUTER_API_KEY='replace-me'

helm upgrade --install chat-api . \
  --namespace chat-api \
  --set openrouterSecretRefName=chat-openrouter
~~~

## Configuration

| Value | Default | Purpose |
| --- | --- | --- |
| `image.repository` | `ghcr.io/justgithubaccount/app-poly-gitops-fastapi` | Runtime image |
| `image.tag` | `1.1.2` | Runtime image tag |
| `replicaCount` | `1` | Deployment replicas |
| `service.port` | `80` | Service port |
| `openrouter.apiUrl` | OpenRouter chat-completions endpoint | Provider endpoint |
| `openrouter.defaultModel` | `anthropic/claude-opus-4` | Model identifier |
| `openrouterSecretRefName` | empty | Existing provider Secret |
| `postgresSecretRefName` | empty | Existing database Secret |
| `ingress.enabled` | `false` | Render an Ingress |
| `extraEnv` | `[]` | Additional container environment entries |

See [values.yaml](values.yaml) for resource requests, probes, telemetry settings,
Ingress options, and the complete value set.

## Repository structure

- `Chart.yaml` — chart metadata
- `values.yaml` — default values
- `templates/` — Kubernetes templates
- `tests/test_chart.sh` — lint and rendered-contract checks

Run the repository check with:

~~~bash
bash tests/test_chart.sh
~~~

## Related repositories

- [app-poly-gitops-fastapi](https://github.com/justgithubaccount/app-poly-gitops-fastapi) — packaged application
- [app-poly-gitops-k8s](https://github.com/justgithubaccount/app-poly-gitops-k8s) — environment-specific GitOps values
- [app-poly-gitops-infra](https://github.com/justgithubaccount/app-poly-gitops-infra) — cluster provisioning and Argo CD bootstrap
- [app-mono-gitops](https://github.com/justgithubaccount/app-mono-gitops) — archived predecessor

## License

MIT
