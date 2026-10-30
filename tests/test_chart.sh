#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

render() {
  helm template chat-api "${repo_root}" --namespace smoke "$@"
}

assert_yaml_resources() {
  python3 - "$1" <<'PY'
import pathlib
import sys

import yaml

documents = list(yaml.safe_load_all(pathlib.Path(sys.argv[1]).read_text()))
resources = [document for document in documents if document is not None]
assert resources, "render did not contain Kubernetes resources"
for resource in resources:
    assert isinstance(resource, dict), resource
    assert resource.get("apiVersion"), resource
    assert resource.get("kind"), resource
    assert isinstance(resource.get("metadata"), dict), resource
    assert resource["metadata"].get("name"), resource
PY
}

helm lint "${repo_root}"

default_render="${tmp_dir}/default.yaml"
render > "${default_render}"
assert_yaml_resources "${default_render}"
test "$(sha256sum "${default_render}" | cut -d' ' -f1)" = \
  "eccee8f126eec4287d1ccf664414f73632b70a6dfa46357b8c31f7d54e96637f"
grep -q 'namespace: smoke' "${default_render}"
grep -q 'image: "ghcr.io/justgithubaccount/app-poly-gitops-fastapi:1.1.2"' "${default_render}"
! grep -q 'secretRef:' "${default_render}"
! grep -q 'command:' "${default_render}"
! grep -q '^kind: Ingress$' "${default_render}"

created_sa="${tmp_dir}/created-sa.yaml"
render --set serviceAccount.name=existing-compatible-name > "${created_sa}"
test "$(grep -c '^kind: ServiceAccount$' "${created_sa}")" -eq 1
grep -q 'name: existing-compatible-name' "${created_sa}"
grep -q 'serviceAccountName: existing-compatible-name' "${created_sa}"

existing_sa="${tmp_dir}/existing-sa.yaml"
render --set serviceAccount.create=false --set serviceAccount.name=precreated-chat-api > "${existing_sa}"
! grep -q '^kind: ServiceAccount$' "${existing_sa}"
grep -q 'serviceAccountName: precreated-chat-api' "${existing_sa}"

if render --set serviceAccount.create=false --set-string serviceAccount.name= \
  > "${tmp_dir}/invalid-sa.yaml" 2> "${tmp_dir}/invalid-sa.err"; then
  echo "serviceAccount.create=false without serviceAccount.name unexpectedly rendered" >&2
  exit 1
fi
grep -q 'serviceAccount.name is required' "${tmp_dir}/invalid-sa.err"

internal_secret="${tmp_dir}/internal-secret.yaml"
render --set createInternalSecret=true > "${internal_secret}"
grep -q '^kind: Secret$' "${internal_secret}"
grep -A3 'envFrom:' "${internal_secret}" | grep -q 'name: chat-api-config'

external_postgres="${tmp_dir}/external-postgres.yaml"
render \
  --set postgres.externalService.enabled=true \
  --set postgres.externalService.host=db.example.internal \
  > "${external_postgres}"
grep -q '^kind: Service$' "${external_postgres}"
grep -q 'externalName: db.example.internal' "${external_postgres}"
! grep -q 'name: DATABASE_URL' "${external_postgres}"
if render --set postgres.externalService.enabled=true \
  > "${tmp_dir}/invalid-postgres.yaml" 2> "${tmp_dir}/invalid-postgres.err"; then
  echo "external Postgres service without a host unexpectedly rendered" >&2
  exit 1
fi
grep -q 'postgres.externalService.host is required' "${tmp_dir}/invalid-postgres.err"

ingress="${tmp_dir}/ingress.yaml"
render \
  --set namespace=application \
  --set ingress.enabled=true \
  --set ingress.host=chat.example.test \
  > "${ingress}"
grep -q '^kind: Ingress$' "${ingress}"
grep -A5 '^kind: Ingress$' "${ingress}" | grep -q 'namespace: application'
grep -q 'host: "chat.example.test"' "${ingress}"
if render --set ingress.enabled=true \
  > "${tmp_dir}/invalid-ingress.yaml" 2> "${tmp_dir}/invalid-ingress.err"; then
  echo "enabled ingress without a host unexpectedly rendered" >&2
  exit 1
fi
grep -q 'ingress.host is required' "${tmp_dir}/invalid-ingress.err"

for manifest in "${default_render}" "${created_sa}" "${existing_sa}" \
  "${internal_secret}" "${external_postgres}" "${ingress}"; do
  assert_yaml_resources "${manifest}"
  kubeconform -strict -summary -ignore-missing-schemas "${manifest}"
done

workflow="${repo_root}/.github/workflows/validate.yaml"
test -f "${workflow}"
grep -q 'bash tests/test_chart.sh' "${workflow}"
