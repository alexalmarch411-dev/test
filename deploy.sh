#!/usr/bin/env bash
set -euo pipefail

TF_DIR="terraform/envs/prod"
MODE="${1:-apply}"

if [[ -z "${YC_CLOUD_ID:-}" ]]; then
  echo "❌ YC_CLOUD_ID не задан"
  echo "   Выполните: export YC_CLOUD_ID=\$(yc config get cloud-id)"
  exit 1
fi

if [[ -z "${YC_FOLDER_ID:-}" ]]; then
  echo "❌ YC_FOLDER_ID не задан"
  echo "   Выполните: export YC_FOLDER_ID=\$(yc config get folder-id)"
  exit 1
fi

if [[ -z "${YC_TOKEN:-}" ]]; then
  echo "❌ YC_TOKEN не задан"
  echo "   Выполните: export YC_TOKEN=\$(yc iam create-token)"
  exit 1
fi

case "$MODE" in
  apply)
    cd "$TF_DIR"
    terraform init

    echo "=== 1. Create infrastructure ==="
    terraform apply -auto-approve \
      -target=module.network \
      -target=module.k8s_cluster \
      -target=module.k8s_node_group \
      -target=yandex_container_registry.app

    echo "=== 2. Auth + Build & Push image ==="
    yc container registry configure-docker
    REGISTRY_IMAGE=$(terraform output -raw registry_image)
    cd ../../..
    docker build --no-cache --platform linux/amd64 \
      --build-arg BUILD_TIMESTAMP=$(date +%s) \
      -t "$REGISTRY_IMAGE:latest" app_python
    docker push "$REGISTRY_IMAGE:latest"
    cd "$TF_DIR"

    echo "=== 3. Wait for cluster to become reachable ==="
    ENDPOINT=$(terraform output -raw master_endpoint)
    for i in $(seq 1 30); do
      if curl -sk --connect-timeout 5 "${ENDPOINT}/version" >/dev/null 2>&1; then
        echo "Cluster is reachable"
        break
      fi
      echo "Attempt $i/30 - not yet reachable, waiting 10s..."
      sleep 10
    done

    echo "=== 4. Deploy Helm chart ==="
    terraform apply -auto-approve

    cd ../../..
    echo "=== Done ==="
    echo "Image: $REGISTRY_IMAGE:latest"
    ;;

  destroy)
    cd "$TF_DIR"

    echo "=== 1. Delete images from registry ==="
    REGISTRY_ID=$(terraform output -raw registry_id 2>/dev/null || \
                  terraform state show yandex_container_registry.app 2>/dev/null | \
                  awk '/^id /{print $3}' || true)
    if [[ -z "$REGISTRY_ID" ]]; then
      REGISTRY_ID=$(yc container registry list --format json | \
                    jq -r '.[] | select(.name | endswith("-registry")) | .id' 2>/dev/null || true)
    fi
    if [[ -n "$REGISTRY_ID" ]]; then
      yc container image list --registry-id "$REGISTRY_ID" --format json | \
        jq -r '.[].id' | xargs -r yc container image delete
    fi

    echo "=== 2. Destroy infrastructure ==="
    terraform destroy -auto-approve

    echo "=== 3. Delete orphaned CSI disks ==="
    yc compute disk list --format json | \
      jq -r '.[] | select(.name | startswith("k8s-csi-")) | .id' | xargs -r yc compute disk delete

    echo "=== Done ==="
    ;;

  *)
    echo "Usage: $0 [apply|destroy]"
    exit 1
    ;;
esac
