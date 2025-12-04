# Chat API Helm Chart

Helm chart для деплоя [Chat API Microservice](https://github.com/justgithubaccount/app-poly-gitops-fastapi) в Kubernetes.

## Быстрый старт

### 1. Создать secrets

```bash
# OpenRouter API key
kubectl create secret generic chat-openrouter \
  --namespace chat-api \
  --from-literal=OPENROUTER_API_KEY=sk-or-v1-...

# PostgreSQL connection
kubectl create secret generic chat-postgres \
  --namespace chat-api \
  --from-literal=DATABASE_URL=postgresql://user:pass@host:5432/db
```

### 2. Установить chart

```bash
helm install chat-api . \
  --namespace chat-api \
  --create-namespace
```

### 3. Проверить

```bash
kubectl get pods -n chat-api
kubectl logs -f deployment/chat-api -n chat-api
```

## Конфигурация

### Основные параметры

| Параметр | Описание | Default |
|----------|----------|---------|
| `replicaCount` | Количество реплик | `2` |
| `image.repository` | Docker image | `ghcr.io/justgithubaccount/chat-api` |
| `image.tag` | Image tag | `1.0.0` |
| `containerPort` | Порт приложения | `8000` |
| `service.type` | Тип сервиса | `ClusterIP` |
| `service.port` | Порт сервиса | `80` |

### Resources

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### OpenRouter

| Параметр | Описание | Default |
|----------|----------|---------|
| `openrouter.apiUrl` | API endpoint | `https://openrouter.ai/api/v1/chat/completions` |
| `openrouter.defaultModel` | LLM модель | `anthropic/claude-opus-4` |
| `openrouterSecretRefName` | Secret с API key | `chat-openrouter` |

### PostgreSQL

| Параметр | Описание | Default |
|----------|----------|---------|
| `postgresSecretRefName` | Secret с DATABASE_URL | `chat-postgres` |
| `postgres.externalService.enabled` | ExternalName service | `false` |

### Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  host: chat-api.example.com
  path: /
  tls: true
```

### OpenTelemetry

```yaml
env:
  OTEL_SERVICE_NAME: "chat-api"
  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector:4318"
  OTEL_TRACES_EXPORTER: "otlp"
  OTEL_LOGS_EXPORTER: "otlp"
```

## Структура

```
.
├── Chart.yaml          # Metadata (v0.3.0)
├── values.yaml         # Default values
└── templates/
    ├── _helpers.tpl    # Template helpers
    ├── deployment.yaml # Deployment
    ├── service.yaml    # ClusterIP Service
    ├── ingress.yaml    # Ingress (optional)
    ├── secret.yaml     # Secret (optional)
    ├── serviceaccount.yaml
    └── pg-service.yaml # PostgreSQL ExternalName
```

## Health Checks

Chart настраивает probes на endpoint `/health`:

- **Readiness**: initial 5s, period 10s
- **Liveness**: initial 10s, period 30s

## Примеры

### Минимальный деплой

```bash
helm install chat-api . \
  --set image.tag=latest \
  --namespace chat-api \
  --create-namespace
```

### С Ingress

```bash
helm install chat-api . \
  --set ingress.enabled=true \
  --set ingress.host=chat.example.com \
  --set ingress.tls=true \
  --namespace chat-api
```

### Custom values

```bash
helm install chat-api . \
  -f my-values.yaml \
  --namespace chat-api
```

## Связанные репозитории

- [app-poly-gitops-fastapi](https://github.com/justgithubaccount/app-poly-gitops-fastapi) — FastAPI приложение
- [app-crewai-cluster](https://github.com/justgithubaccount/app-crewai-cluster) — CrewAI агенты
- [app-release](https://github.com/justgithubaccount/app-release) — GitOps манифесты

## License

MIT
