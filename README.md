# Home Server

A collection of configurations and deployments for running a home server infrastructure.

## Projects

### K3s Kubernetes Cluster

A lightweight Kubernetes cluster setup using k3s, configured for 1-3 node deployments with Traefik as the ingress controller.

**Location**: [`k3s/`](k3s/)

**Features**:
- Single or multi-node k3s cluster configuration
- Traefik v2 ingress controller with dashboard
- Example applications demonstrating routing
- Comprehensive setup documentation

**Quick Start**:
```bash
# Install k3s (single node)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Deploy Traefik
kubectl apply -f k3s/manifests/traefik/05-crds.yaml
kubectl apply -f k3s/manifests/traefik/
```

See the [k3s README](k3s/README.md) for detailed documentation.

## Getting Started

Each project directory contains its own README with specific setup instructions and documentation.

## Repository Structure

```
.
├── k3s/                    # K3s Kubernetes cluster configuration
│   ├── manifests/          # Kubernetes manifests
│   │   ├── traefik/        # Traefik ingress controller
│   │   └── examples/       # Example applications
│   ├── docs/               # Documentation
│   └── README.md           # K3s project documentation
└── README.md               # This file
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

See [LICENSE](LICENSE) for details.
