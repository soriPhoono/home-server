#!/bin/bash
# Validation script for k3s and Traefik deployment

set -e

echo "=== K3s and Traefik Deployment Validation ==="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl or k3s first."
    exit 1
fi

echo "✅ kubectl found"
echo ""

# Check cluster connectivity
echo "Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to cluster. Is k3s running?"
    exit 1
fi
echo "✅ Cluster is reachable"
echo ""

# Check nodes
echo "Cluster nodes:"
kubectl get nodes
echo ""

# Check if Traefik namespace exists
echo "Checking Traefik namespace..."
if kubectl get namespace traefik &> /dev/null; then
    echo "✅ Traefik namespace exists"
else
    echo "⚠️  Traefik namespace not found. Run: kubectl apply -f k3s/manifests/traefik/"
fi
echo ""

# Check Traefik deployment
echo "Checking Traefik deployment..."
if kubectl get deployment traefik -n traefik &> /dev/null; then
    READY=$(kubectl get deployment traefik -n traefik -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment traefik -n traefik -o jsonpath='{.status.replicas}')
    
    if [ "$READY" == "$DESIRED" ]; then
        echo "✅ Traefik deployment is ready ($READY/$DESIRED replicas)"
    else
        echo "⚠️  Traefik deployment not ready ($READY/$DESIRED replicas)"
    fi
else
    echo "⚠️  Traefik deployment not found"
fi
echo ""

# Check Traefik service
echo "Checking Traefik service..."
if kubectl get service traefik -n traefik &> /dev/null; then
    echo "✅ Traefik service exists"
    EXTERNAL_IP=$(kubectl get service traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$EXTERNAL_IP" ]; then
        echo "ℹ️  LoadBalancer IP: <pending> (this is normal for bare-metal)"
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
        echo "ℹ️  You can use node IP: $NODE_IP"
    else
        echo "ℹ️  LoadBalancer IP: $EXTERNAL_IP"
    fi
else
    echo "⚠️  Traefik service not found"
fi
echo ""

# Check IngressRoutes
echo "Checking IngressRoutes..."
INGRESSROUTES=$(kubectl get ingressroutes -A --no-headers 2>/dev/null | wc -l)
echo "ℹ️  Found $INGRESSROUTES IngressRoute(s)"
if [ "$INGRESSROUTES" -gt 0 ]; then
    kubectl get ingressroutes -A
fi
echo ""

# Check example namespace
if kubectl get namespace example &> /dev/null; then
    echo "✅ Example namespace exists"
    if kubectl get deployment whoami -n example &> /dev/null; then
        echo "✅ Example whoami application deployed"
    fi
    echo ""
fi

# Summary
echo "=== Summary ==="
echo "Run the following to check Traefik logs:"
echo "  kubectl logs -n traefik -l app=traefik -f"
echo ""
echo "Access Traefik dashboard (add to /etc/hosts):"
echo "  http://traefik.local/dashboard/"
echo ""
echo "Access example app (add to /etc/hosts):"
echo "  http://whoami.local"
