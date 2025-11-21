# Home Server - K3s Home Lab

This repository contains raw Kubernetes manifests for learning Kubernetes structures intimately. By using raw YAML files instead of Helm charts, you'll gain a deeper understanding of how Kubernetes resources work together.

## Prerequisites

- A Linux machine (physical or virtual) with at least 1GB RAM
- Root or sudo access

## Installing K3s

K3s is a lightweight Kubernetes distribution perfect for home labs and edge computing. To install k3s on a single node, run:

```bash
curl -sfL https://get.k3s.io | sh -
```

After installation, k3s will automatically start and be configured to start on boot. The kubeconfig file will be located at `/etc/rancher/k3s/k3s.yaml`.

To use kubectl commands, you can either:
- Use `sudo kubectl` for commands, or
- Copy the kubeconfig: `sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $USER ~/.kube/config`

## Applying Manifests

To apply any manifest file to your cluster:

```bash
kubectl apply -f <filename>
```

To apply an entire directory:

```bash
kubectl apply -f <directory>/
```

To delete resources:

```bash
kubectl delete -f <filename>
```

## Repository Structure

```
apps/
├── whoami/           # Simple web service that returns request information
│   ├── namespace.yaml    # Namespace definition
│   ├── deployment.yaml   # Application deployment
│   ├── service.yaml      # Service to expose the deployment
│   └── ingress.yaml      # Ingress for external access
```

## Getting Started with Whoami App

The `whoami` application is a simple web service that returns information about the HTTP request. It's perfect for learning Kubernetes basics.

1. Apply all whoami manifests:
   ```bash
   kubectl apply -f apps/whoami/
   ```

2. Verify the deployment:
   ```bash
   kubectl get all -n homelab
   ```

3. Access the application (requires configuring `whoami.local` in your `/etc/hosts` file):
   ```bash
   echo "127.0.0.1 whoami.local" | sudo tee -a /etc/hosts
   ```

4. Then visit `http://whoami.local` in your browser (k3s includes Traefik ingress controller by default)

## Learning Resources

Each YAML file in this repository includes detailed comments explaining:
- What each resource does
- Why specific fields are needed
- How resources relate to each other

Start with the `apps/whoami/` directory to learn the basics of:
- Namespaces (logical isolation)
- Deployments (running applications)
- Services (networking)
- Ingress (external access)
