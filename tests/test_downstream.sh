#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
k8s_repo="${1:?usage: tests/test_downstream.sh /path/to/app-poly-gitops-k8s}"
application="${k8s_repo}/tenants/product-team/apps/chat/base/application.yaml"
values="${k8s_repo}/tenants/product-team/apps/chat/overlays/dev/values.yaml"

test -f "${application}"
test -f "${values}"
grep -q 'repoURL: https://github.com/justgithubaccount/app-poly-gitops-helm' "${application}"
grep -q 'targetRevision: v0.4.1' "${application}"

rendered="$(helm template chat-api "${repo_root}" --namespace product-team -f "${values}")"
grep -q 'namespace: product-team' <<<"${rendered}"
grep -q 'image: "ghcr.io/justgithubaccount/app-poly-gitops-fastapi:1.1.2"' <<<"${rendered}"
grep -q 'serviceAccountName: chat-api' <<<"${rendered}"
