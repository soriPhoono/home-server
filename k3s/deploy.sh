#!/bin/bash
# Quick deployment script for Traefik on k3s

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== K3s Traefik Deployment Script ==="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install k3s first."
    echo ""
    echo "To install k3s (single node):"
    echo '  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -'
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to cluster. Is k3s running?"
    exit 1
fi

echo "✅ Connected to k3s cluster"
echo ""

# Deploy CRDs first
echo "Deploying Traefik CRDs..."
kubectl apply -f "$SCRIPT_DIR/manifests/traefik/05-crds.yaml"
echo ""

# Wait a moment for CRDs to be registered
sleep 2

# Deploy all Traefik components
echo "Deploying Traefik components..."
kubectl apply -f "$SCRIPT_DIR/manifests/traefik/"
echo ""

# Wait for Traefik to be ready
echo "Waiting for Traefik to be ready (this may take a minute)..."
kubectl wait --for=condition=available --timeout=120s deployment/traefik -n traefik 2>/dev/null || true
echo ""

# Check status
echo "Checking Traefik status..."
kubectl get pods -n traefik
echo ""
kubectl get svc -n traefik
echo ""

# Get LoadBalancer IP
EXTERNAL_IP=$(kubectl get service traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$EXTERNAL_IP" ]; then
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo "✅ Traefik deployed successfully!"
    echo ""
    echo "Note: LoadBalancer is pending (normal for bare-metal installations)"
    echo "You can access Traefik using the node IP: $NODE_IP"
else
    echo "✅ Traefik deployed successfully!"
    echo ""
    echo "LoadBalancer IP: $EXTERNAL_IP"
fi

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Add to /etc/hosts:"
if [ -z "$EXTERNAL_IP" ]; then
    echo "   $NODE_IP traefik.local whoami.local"
else
    echo "   $EXTERNAL_IP traefik.local whoami.local"
fi
echo ""
echo "2. Access Traefik dashboard:"
echo "   http://traefik.local/dashboard/"
echo ""
echo "3. Deploy example application (optional):"
echo "   kubectl apply -f $SCRIPT_DIR/manifests/examples/whoami.yaml"
echo "   Then visit: http://whoami.local"
echo ""
echo "4. View Traefik logs:"
echo "   kubectl logs -n traefik -l app=traefik -f"
