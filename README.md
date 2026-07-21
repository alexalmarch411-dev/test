# App Stack

Python FastAPI микросервис с MongoDB, разворачиваемый в Kubernetes через Helm. Инфраструктура — Yandex Cloud через Terraform.

```
├── app_python/                     # FastAPI микросервис
│   ├── main.py                     # API: GET /, /health, /metrics
│   ├── Dockerfile                  # multi-stage, non-root
│   ├── requirements.txt
│   └── docker-compose.yaml         # Локальный запуск app + mongo
├── terraform/                      # Yandex Cloud
│   ├── modules/
│   │   ├── network/                # VPC, subnets, NAT, SG
│   │   ├── k8s-cluster/            # Managed master
│   │   └── k8s-node-group/         # Worker pool
│   └── envs/prod/
│       ├── main.tf                 # Ресурсы + Helm release
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── helm/app-stack/                 # Umbrella helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── charts/
│       ├── web/                    # Deployment, Service, Ingress, ConfigMap, Secret
│       ├── mongodb/                # StatefulSet, Service, PVC
│       └── network-policy/         # default-deny, allow-web-to-mongo, etc.
├── deploy.sh                       # apply / destroy
└── README.md
```

---

## Быстрый старт

### Локально (без K8s)

```bash
cd app_python
docker compose up
curl http://localhost:8080/        # {"status": "ok"}
curl http://localhost:8080/health  # {"mongodb": "ok"}
curl http://localhost:8080/metrics  # Prometheus
```

### В kind (локальный K8s)

```bash
kind create cluster --name dev
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

cd app_python && docker build -t app_python-app:latest . && kind load docker-image app_python-app:latest --name dev && cd ..

rm -f helm/app-stack/charts/*.tgz
helm package helm/app-stack/charts/web -d helm/app-stack/charts/
helm package helm/app-stack/charts/mongodb -d helm/app-stack/charts/
helm package helm/app-stack/charts/network-policy -d helm/app-stack/charts/
helm install myapp ./helm/app-stack

kubectl port-forward svc/myapp-web 8080:8080
curl http://localhost:8080/
```

### В Yandex Cloud

```bash
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id <sa-id>)

cp terraform/envs/prod/terraform.tfvars.example terraform/envs/prod/terraform.tfvars
vim terraform/envs/prod/terraform.tfvars

./deploy.sh          # terraform → build → push → restart
./deploy.sh destroy  # terraform destroy
```

---

## Микросервис

### Эндпоинты

| Метод | Путь | Ответ |
|-------|------|-------|
| GET | `/` | `{"status": "ok"}` |
| GET | `/health` | `{"mongodb": "ok"}` / 503 |
| GET | `/metrics` | Prometheus-метрики |

### Prometheus-метрики
- `http_requests_total{method, path, status}`
- `mongodb_ping_duration_seconds`
- `mongodb_up`

---

## Terraform

Провайдер Yandex читает `YC_CLOUD_ID`, `YC_FOLDER_ID`, `YC_TOKEN` из окружения.

**Модули:** network (VPC, subnets, NAT, SG), k8s-cluster (managed master), k8s-node-group (private workers).  
**Ресурсы:** container registry, helm release с образом из registry.

Обязательные переменные (`terraform.tfvars`): `service_account_id`, `node_service_account_id`.

---

## Helm

Umbrella chart из трёх subchart:

| Subchart | Роль |
|----------|------|
| `web` | FastAPI: Deployment, Service ClusterIP, Ingress, ConfigMap, Secret |
| `mongodb` | MongoDB: StatefulSet, Service, PVC |
| `network-policy` | default-deny-all, allow-dns, allow-web-to-mongo, allow-ingress-to-web |

Labels — `app:` (без `app.kubernetes.io/name`).  
MongoDB URI формируется динамически из `{{ .Release.Name }}-mongodb:27017`.

### NetworkPolicy

| Политика | Действие |
|----------|----------|
| `default-deny-all` | Блокирует весь трафик |
| `allow-dns` | DNS (UDP/TCP 53) |
| `allow-web-to-mongo` | Входящие к MongoDB от web |
| `allow-web-egress-to-mongo` | Исходящие от web к MongoDB |
| `allow-ingress-to-web` | Входящие от ingress-nginx к web |

---

## deploy.sh

Единый скрипт для работы с Yandex Cloud:

```bash
./deploy.sh          # terraform apply → docker build/push → restart
./deploy.sh destroy  # terraform destroy
```

Проверяет наличие `YC_CLOUD_ID`, `YC_FOLDER_ID`, `YC_TOKEN` перед запуском.

export TF_VAR_service_account_id="ajesphqeilslrldhqhsj"
export TF_VAR_node_service_account_id="ajesphqeilslrldhqhsj"
