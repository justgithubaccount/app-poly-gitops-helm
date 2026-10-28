#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

helm lint "${repo_root}"
rendered="$(helm template chat-api "${repo_root}" --namespace smoke)"

grep -q 'namespace: smoke' <<<"${rendered}"
grep -q 'image: "ghcr.io/justgithubaccount/app-poly-gitops-fastapi:1.1.1"' <<<"${rendered}"
! grep -q 'secretRef:' <<<"${rendered}"
! grep -q 'command:' <<<"${rendered}"
