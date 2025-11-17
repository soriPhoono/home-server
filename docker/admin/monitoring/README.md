# Monitoring Stack

This directory contains the monitoring and observability stack for the home-server infrastructure.

## 📊 Overview

The monitoring stack provides comprehensive observability for Docker Swarm containers, including metrics collection, log aggregation, and visualization through a unified dashboard interface.

## 🏗️ Architecture

### Services

1. **Grafana** (Dashboard & Visualization)
   - Web UI for metrics and logs visualization
   - Accessible at: `https://monitoring.admin.${DOMAIN_NAME}`
   - Default port: 3000 (internal)
   - Data sources: Prometheus (metrics), Loki (logs)

2. **Prometheus** (Metrics Collection & Storage)
   - Time-series database for metrics
   - Scrapes metrics from cAdvisor and other exporters
   - Internal port: 9090
   - Configured via: `prometheus.yml`

3. **Loki** (Log Aggregation)
   - Log aggregation system
   - Receives logs from Promtail
   - Internal port: 3100
   - Configured via: `loki.yml`

4. **Promtail** (Log Collector)
   - Agent for collecting and shipping logs to Loki
   - Collects from: system logs (`/var/log`) and Docker container logs
   - Internal port: 9080
   - Configured via: `promtail.yml`

5. **cAdvisor** (Container Metrics)
   - Collects container resource usage and performance metrics
   - Runs on all Docker Swarm nodes (global mode)
   - Metrics exposed for Prometheus scraping
   - Labeled with `prometheus-job=cadvisor`

### Network Architecture

```
┌─────────────────────────────────────────────────────┐
│                   External Traffic                   │
│              (via Traefik Reverse Proxy)            │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │    Grafana    │ ◄─── UI Access
              │   (port 3000) │
              └───┬───────┬───┘
                  │       │
          ┌───────┘       └────────┐
          ▼                        ▼
  ┌───────────────┐        ┌──────────────┐
  │  Prometheus   │        │     Loki     │
  │  (port 9090)  │        │  (port 3100) │
  └───────┬───────┘        └──────▲───────┘
          │                       │
          │                       │
          ▼                       │
  ┌───────────────┐               │
  │   cAdvisor    │               │
  │  (all nodes)  │               │
  └───────────────┘               │
                                  │
                          ┌───────┴───────┐
                          │   Promtail    │
                          │  (all nodes)  │
                          └───────────────┘
                                  │
                    ┌─────────────┴──────────────┐
                    ▼                            ▼
            ┌───────────────┐          ┌────────────────┐
            │  System Logs  │          │ Container Logs │
            │  (/var/log)   │          │   (Docker)     │
            └───────────────┘          └────────────────┘
```

## 🚀 Deployment

### Prerequisites

1. Docker Swarm cluster initialized
2. `proxy_public` network created (for Traefik integration)
3. `DOMAIN_NAME` environment variable set
4. Traefik deployed and running (from `docker/admin/proxy`)

### Deploy the Stack

Using Portainer:
1. Navigate to **Stacks** → **Add stack**
2. Select **Git Repository**
3. Repository URL: `https://github.com/soriphoono/home-server.git`
4. Compose path: `docker/admin/monitoring/docker-compose.yml`
5. Add environment variable: `DOMAIN_NAME=your-domain.com`
6. Deploy the stack

Using Docker CLI:
```bash
cd docker/admin/monitoring
docker stack deploy -c docker-compose.yml monitoring
```

### Verify Deployment

```bash
# Check all services are running
docker service ls | grep monitoring

# Check service logs
docker service logs monitoring_grafana
docker service logs monitoring_prometheus
docker service logs monitoring_loki
```

## 🔧 Configuration

### Prometheus Configuration

Edit `prometheus.yml` to:
- Adjust scrape intervals
- Add new scrape targets
- Configure service discovery
- Add alert rules

Current configuration:
- Scrape interval: 15 seconds
- Evaluation interval: 15 seconds
- Auto-discovers Docker Swarm services with `prometheus-job` label

### Loki Configuration

Edit `loki.yml` to:
- Adjust retention settings
- Configure storage backend
- Tune performance parameters

Current configuration:
- Storage: Filesystem-based
- Schema: v13 (TSDB)
- Retention: Not configured (see IMPROVEMENTS.md)

### Promtail Configuration

Edit `promtail.yml` to:
- Add new log sources
- Configure parsing pipelines
- Add labels and metadata

Current log sources:
- System logs: `/var/log/**/*.log`
- Docker logs: `/var/lib/docker/containers/*/*.log`

## 📈 Usage

### Access Grafana

1. Navigate to: `https://monitoring.admin.${DOMAIN_NAME}`
2. Default credentials:
   - Username: `admin`
   - Password: `admin` (change on first login)

### Configure Data Sources

After first login:

1. **Add Prometheus:**
   - Configuration → Data Sources → Add data source
   - Select Prometheus
   - URL: `http://prometheus:9090`
   - Save & Test

2. **Add Loki:**
   - Configuration → Data Sources → Add data source
   - Select Loki
   - URL: `http://loki:3100`
   - Save & Test

### Import Dashboards

Recommended dashboards:
- **Docker and System Monitoring**: ID 14282
- **Docker Swarm & Container**: ID 609
- **cAdvisor**: ID 14282
- **Loki Dashboard**: ID 13639

To import:
1. Dashboards → New → Import
2. Enter dashboard ID or upload JSON
3. Select Prometheus/Loki as data source
4. Import

### Query Examples

**Prometheus (Metrics):**
```promql
# Container memory usage
container_memory_usage_bytes{name=~".+"}

# CPU usage by container
rate(container_cpu_usage_seconds_total[5m])

# Container restarts
changes(container_start_time_seconds[1h])
```

**Loki (Logs):**
```logql
# All logs from a specific job
{job="docker"}

# Filter logs containing "error"
{job="docker"} |= "error"

# Parse JSON logs
{job="docker"} | json
```

## 🐛 Troubleshooting

### Service Won't Start

```bash
# Check service status
docker service ps monitoring_<service-name> --no-trunc

# Check logs
docker service logs monitoring_<service-name>

# Verify config files
docker config inspect monitoring_prometheus-config
```

### Grafana Can't Connect to Prometheus/Loki

1. Verify services are running: `docker service ls`
2. Check network connectivity: `docker exec <grafana-container> ping prometheus`
3. Verify data source URL uses service name (not localhost)

### No Metrics Appearing

1. Check Prometheus targets: `http://prometheus:9090/targets` (via port-forward)
2. Verify service has `prometheus-job` label
3. Check cAdvisor is running: `docker service ls | grep cadvisor`

### No Logs Appearing

1. Verify Promtail is running: `docker service ps monitoring_promtail`
2. Check Promtail can reach Loki: `docker service logs monitoring_promtail`
3. Verify log paths are correct and accessible

### High Resource Usage

1. Check resource consumption: `docker stats`
2. Consider implementing resource limits (see IMPROVEMENTS.md #4)
3. Adjust retention policies to reduce storage (see IMPROVEMENTS.md #5)

## 🔒 Security Considerations

⚠️ **Current Security Status:**
- Grafana is exposed via Traefik with HTTPS
- Internal services (Prometheus, Loki) are not authenticated
- Services communicate over internal Docker network

**Recommendations:**
- Change default Grafana admin password immediately
- Review IMPROVEMENTS.md #2 for authentication enhancements
- Implement network policies to restrict service access
- Enable Grafana authentication providers (LDAP, OAuth, etc.)

## 📊 Data Storage

### Volumes

- `prometheus-data`: Prometheus metrics database
- `loki-data`: Loki log storage
- `promtail-data`: Promtail position tracking
- `grafana-data`: Grafana dashboards and settings

### Backup Recommendations

See IMPROVEMENTS.md #7 for detailed backup strategy.

Quick backup:
```bash
# Backup Grafana data
docker run --rm -v monitoring_grafana-data:/data -v $(pwd):/backup ubuntu tar czf /backup/grafana-backup.tar.gz /data

# Backup Prometheus data
docker run --rm -v monitoring_prometheus-data:/data -v $(pwd):/backup ubuntu tar czf /backup/prometheus-backup.tar.gz /data
```

## 🔄 Maintenance

### Updating Services

⚠️ Current images use `:latest` tag (not recommended)

To update:
```bash
# Pull latest images
docker service update --image grafana/grafana:latest monitoring_grafana

# Or redeploy the entire stack
docker stack deploy -c docker-compose.yml monitoring
```

**Better approach:** See IMPROVEMENTS.md #1 for version pinning recommendations.

### Monitoring the Monitoring Stack

- Create dashboards for monitoring service health
- Set up alerts for monitoring service failures
- See IMPROVEMENTS.md #9 for self-monitoring recommendations

## 📚 Further Reading

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [cAdvisor Documentation](https://github.com/google/cadvisor)

## 🔍 Known Issues & Improvements

See [IMPROVEMENTS.md](./IMPROVEMENTS.md) for a comprehensive list of identified improvements and enhancement opportunities for this monitoring stack.

Priority improvements include:
1. Version pinning for all images
2. Security and authentication configuration
3. Alerting system implementation
4. Resource constraints and limits
5. Data retention policies

## 🤝 Contributing

When making changes to this stack:
1. Test in a non-production environment first
2. Update configuration files and documentation
3. Follow the guidelines in IMPROVEMENTS.md
4. Consider backward compatibility
5. Document any breaking changes

---

**Last Updated:** 2025-11-17  
**Maintainer:** [Repository Owner]
