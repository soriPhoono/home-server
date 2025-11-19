# K3s Home Server Project

A basic k3s Kubernetes cluster skeleton for deployment to 1-3 nodes, with Traefik ingress controller.

## Overview

This project provides a ready-to-deploy k3s cluster configuration suitable for home server environments. It includes:

- **K3s**: Lightweight Kubernetes distribution
- **Traefik**: Modern HTTP reverse proxy and load balancer
- **Example Applications**: Sample deployments to demonstrate routing

## Features

- ✅ Single or multi-node (up to 3 nodes) deployment support
- ✅ Traefik v2 as ingress controller
- ✅ Custom Resource Definitions (CRDs) for advanced routing
- ✅ Example application with IngressRoute
- ✅ Dashboard access for Traefik
- ✅ Security-focused configuration (RBAC, security contexts)
- ✅ Resource limits and requests defined

## Quick Start

### 1. Install k3s

```bash
# Single node installation
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
```

For multi-node setup, see [SETUP.md](docs/SETUP.md).

### 2. Deploy Traefik

```bash
# Apply CRDs first
kubectl apply -f k3s/manifests/traefik/05-crds.yaml

# Deploy all Traefik components
kubectl apply -f k3s/manifests/traefik/

# Wait for Traefik to be ready
kubectl wait --for=condition=available --timeout=120s deployment/traefik -n traefik
```

### 3. Deploy Example Application (Optional)

```bash
kubectl apply -f k3s/manifests/examples/whoami.yaml
```

## Project Structure

```
k3s/
├── manifests/
│   ├── traefik/              # Traefik ingress controller
│   │   ├── 00-namespace.yaml
│   │   ├── 01-rbac.yaml
│   │   ├── 02-configmap.yaml
│   │   ├── 03-deployment.yaml
│   │   ├── 04-service.yaml
│   │   ├── 05-crds.yaml
│   │   └── 06-dashboard-ingressroute.yaml
│   └── examples/             # Example applications
│       └── whoami.yaml
└── docs/
    └── SETUP.md              # Detailed setup guide
```

## Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation and configuration instructions
- [Traefik Documentation](https://doc.traefik.io/traefik/) - Official Traefik documentation
- [K3s Documentation](https://docs.k3s.io/) - Official k3s documentation

## Architecture

### Traefik Components

1. **Namespace**: Dedicated `traefik` namespace for isolation
2. **RBAC**: ServiceAccount, ClusterRole, and ClusterRoleBinding for proper permissions
3. **ConfigMap**: Traefik configuration with entry points for HTTP and HTTPS
4. **Deployment**: Traefik proxy with resource limits and security contexts
5. **Services**: 
   - LoadBalancer service for external traffic (ports 80, 443)
   - ClusterIP service for dashboard access (port 8080)
6. **CRDs**: Custom Resource Definitions for IngressRoute, Middleware, and TLSOption

### Network Flow

```
Internet → LoadBalancer (80/443) → Traefik → Services → Pods
```

## Access Points

After deployment, you can access:

- **Traefik Dashboard**: http://traefik.local/dashboard/ (add to /etc/hosts)
- **Example App**: http://whoami.local (add to /etc/hosts)

## Resource Requirements

### Minimum per Node
- CPU: 1 core
- RAM: 512MB
- Disk: 10GB

### Recommended per Node
- CPU: 2 cores
- RAM: 2GB
- Disk: 20GB

## Scaling

The skeleton supports 1-3 nodes:
- **1 Node**: All workloads run on a single node (development/testing)
- **2-3 Nodes**: Workloads distributed across nodes (high availability)

To scale applications:
```bash
kubectl scale deployment <deployment-name> --replicas=<count> -n <namespace>
```

## Security Considerations

- Traefik runs as non-root user (UID 65532)
- Read-only root filesystem enabled
- Capability dropping implemented
- RBAC configured with minimal required permissions
- HTTP to HTTPS redirection configured

## Customization

### Change Traefik Configuration

Edit `k3s/manifests/traefik/02-configmap.yaml` and apply:
```bash
kubectl apply -f k3s/manifests/traefik/02-configmap.yaml
kubectl rollout restart deployment/traefik -n traefik
```

### Add New Applications

Create manifests in `k3s/manifests/` and apply:
```bash
kubectl apply -f k3s/manifests/<your-manifest>.yaml
```

### Configure TLS/HTTPS

1. Create a TLS secret with your certificates
2. Update IngressRoute to use TLS
3. Apply the changes

## Troubleshooting

### Check Traefik Status
```bash
kubectl get all -n traefik
kubectl logs -n traefik -l app=traefik
```

### Check IngressRoutes
```bash
kubectl get ingressroutes -A
kubectl describe ingressroute <name> -n <namespace>
```

### Common Issues

- **LoadBalancer Pending**: Normal for bare-metal. Use node IP or install MetalLB
- **DNS Resolution**: Add entries to `/etc/hosts` for testing
- **Pod Not Starting**: Check logs with `kubectl logs` and events with `kubectl describe pod`

## Contributing

Feel free to submit issues or pull requests to improve this skeleton.

## License

This project structure is provided as-is for home server deployments.

## Additional Resources

- [K3s GitHub](https://github.com/k3s-io/k3s)
- [Traefik GitHub](https://github.com/traefik/traefik)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
