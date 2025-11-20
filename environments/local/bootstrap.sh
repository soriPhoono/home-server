#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="homelab"

if ! k3d cluster list | grep -q "^${CLUSTER_NAME}\b"; then
  k3d cluster create "${CLUSTER_NAME}" \
      -s 1 -a 0 \
      --volume "/dev/mapper/crypted:/dev/mapper/crypted@all" \
      --k3s-arg "--kubelet-arg=fail-swap-on=false@all" \
      --image rancher/k3s:latest
fi

kubectl config use-context "k3d-${CLUSTER_NAME}"

kubectl apply -f environments/local/manifests/

cd environments/local
helmfile apply