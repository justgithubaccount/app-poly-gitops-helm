#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

helm lint "${repo_root}"
rendered="$(helm template chat-api "${repo_root}" --namespace smoke)"

grep -q 'namespace: smoke' <<<"${rendered}"
grep -q 'image: "ghcr.io/justgithubaccount/app-poly-gitops-fastapi:1.1.2"' <<<"${rendered}"
! grep -q 'secretRef:' <<<"${rendered}"
! grep -q 'command:' <<<"${rendered}"

workflow="${repo_root}/.github/workflows/validate.yaml"
test -f "${workflow}"
grep -q 'bash tests/test_chart.sh' "${workflow}"
