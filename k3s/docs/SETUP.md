# K3s Cluster Setup Guide

This guide provides instructions for setting up a k3s cluster on 1-3 nodes with Traefik as the ingress controller.

## Prerequisites

- Ubuntu/Debian-based Linux system (or other supported OS)
- Minimum 1 CPU core and 512MB RAM per node
- Root or sudo access
- Network connectivity between nodes (for multi-node setup)

## Single Node Installation

For a single-node k3s cluster:

```bash
# Install k3s with Traefik disabled (we'll deploy our own)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Wait for k3s to be ready
sudo k3s kubectl wait --for=condition=ready node --all --timeout=60s

# Set up kubectl access (optional, for non-root users)
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config
```

## Multi-Node Installation (2-3 Nodes)

### Master Node Setup

On the first (master) node:

```bash
# Install k3s as server with Traefik disabled
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -s - server

# Get the node token for worker nodes
sudo cat /var/lib/rancher/k3s/server/node-token
```

Save the token and note the master node's IP address.

### Worker Node Setup

On each worker node (repeat for each additional node):

```bash
# Replace <MASTER_IP> with the master node IP
# Replace <NODE_TOKEN> with the token from the master node
curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<NODE_TOKEN> sh -
```

### Verify Cluster

On the master node:

```bash
sudo k3s kubectl get nodes
```

You should see all nodes listed with status "Ready".

## Deploy Traefik

Once your k3s cluster is running, deploy Traefik:

```bash
# Deploy Traefik CRDs first
kubectl apply -f k3s/manifests/traefik/05-crds.yaml

# Deploy all Traefik components
kubectl apply -f k3s/manifests/traefik/

# Wait for Traefik to be ready
kubectl wait --for=condition=available --timeout=120s deployment/traefik -n traefik
```

### Verify Traefik Installation

```bash
# Check Traefik pods
kubectl get pods -n traefik

# Check Traefik service
kubectl get svc -n traefik

# Get LoadBalancer IP (may show <pending> on some setups)
kubectl get svc traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Deploy Example Application

To test Traefik routing:

```bash
# Deploy the whoami example application
kubectl apply -f k3s/manifests/examples/whoami.yaml

# Wait for the deployment
kubectl wait --for=condition=available --timeout=60s deployment/whoami -n example
```

### Access the Example Application

Add an entry to your `/etc/hosts` file:

```bash
# Replace <TRAEFIK_IP> with the Traefik LoadBalancer IP or master node IP
echo "<TRAEFIK_IP> whoami.local traefik.local" | sudo tee -a /etc/hosts
```

Then access:
- Example app: http://whoami.local
- Traefik dashboard: http://traefik.local/dashboard/

## Useful Commands

```bash
# Get all resources in traefik namespace
kubectl get all -n traefik

# View Traefik logs
kubectl logs -n traefik -l app=traefik -f

# Check IngressRoutes
kubectl get ingressroutes -A

# Describe a pod
kubectl describe pod <pod-name> -n <namespace>

# Get cluster info
kubectl cluster-info

# Get node information
kubectl get nodes -o wide
```

## Uninstalling

To remove k3s completely:

```bash
# On worker nodes
/usr/local/bin/k3s-agent-uninstall.sh

# On master/server node
/usr/local/bin/k3s-uninstall.sh
```

## Troubleshooting

### Traefik Service Pending

If the LoadBalancer service shows `<pending>`, this is normal for bare-metal installations. You can:
1. Use NodePort instead by changing service type
2. Access via node IP directly
3. Install MetalLB for bare-metal LoadBalancer support

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
```

### Network Issues Between Nodes

Ensure:
- Firewall allows traffic on port 6443 (k3s API)
- Firewall allows traffic on ports 80 and 443 (HTTP/HTTPS)
- Nodes can ping each other

## Next Steps

- Configure TLS certificates for HTTPS
- Set up persistent storage
- Deploy your own applications
- Configure authentication for Traefik dashboard
- Set up monitoring and logging
