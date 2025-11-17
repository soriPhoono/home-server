# Monitoring Stack Improvements

This document tracks identified improvements for the monitoring stack at `docker/admin/monitoring`.

## 🔴 High Priority Issues

### 1. Version Pinning for Container Images
**Status:** Open  
**Priority:** High  
**Category:** Stability & Reproducibility

**Current State:**  
All services use `:latest` tags for Docker images:
- `gcr.io/cadvisor/cadvisor:latest`
- `prom/prometheus:latest`
- `grafana/promtail:latest`
- `grafana/loki:latest`
- `grafana/grafana:latest`

**Problem:**  
Using `:latest` tags can lead to:
- Unpredictable behavior when images are updated
- Difficulty reproducing issues
- Breaking changes being introduced automatically
- Inconsistent deployments across environments

**Recommendation:**  
Pin all images to specific stable versions:
```yaml
cadvisor: gcr.io/cadvisor/cadvisor:v0.47.0
prometheus: prom/prometheus:v2.48.0
promtail: grafana/promtail:2.9.3
loki: grafana/loki:2.9.3
grafana: grafana/grafana:10.2.3
```

### 2. Missing Authentication & Security Configuration
**Status:** Open  
**Priority:** High  
**Category:** Security

**Current State:**  
No authentication is configured for internal monitoring services (Prometheus, Loki, cAdvisor).

**Problem:**  
- Prometheus endpoint accessible without authentication (port 9090)
- Loki endpoint accessible without authentication (port 3100)
- cAdvisor metrics exposed without protection
- Internal services could be accessed if network boundaries are breached

**Recommendation:**  
1. Enable Grafana authentication as the primary access point (already exposed via Traefik)
2. Configure Prometheus to only accept connections from Grafana
3. Configure Loki to only accept connections from Grafana and Promtail
4. Add network policies to restrict service-to-service communication
5. Consider basic auth for Prometheus if direct access is needed
6. Implement authentication for cAdvisor or restrict network access

### 3. Missing Alerting System
**Status:** Open  
**Priority:** High  
**Category:** Operations

**Current State:**  
No alerting mechanism is configured. Prometheus is collecting metrics but not configured to send alerts.

**Problem:**  
- No proactive notification of issues
- System problems may go unnoticed
- Manual monitoring required
- No integration with incident management

**Recommendation:**  
1. Add Alertmanager service to the stack
2. Configure Prometheus alert rules for:
   - Container health and restarts
   - Resource usage thresholds (CPU, memory, disk)
   - Service availability
   - Docker swarm node status
3. Configure Alertmanager receivers (email, Slack, PagerDuty, etc.)
4. Set up alert routing and grouping policies

**Example Configuration:**
```yaml
alertmanager:
  image: prom/alertmanager:v0.26.0
  command:
    - '--config.file=/etc/alertmanager/config.yml'
    - '--storage.path=/alertmanager'
  configs:
    - source: alertmanager-config
      target: /etc/alertmanager/config.yml
  volumes:
    - alertmanager-data:/alertmanager
  networks:
    - default
  deploy:
    mode: replicated
    replicas: 1
    placement:
      constraints:
        - node.role == manager
```

## 🟡 Medium Priority Issues

### 4. Missing Resource Constraints
**Status:** Open  
**Priority:** Medium  
**Category:** Resource Management

**Current State:**  
No resource limits or reservations are defined for any service.

**Problem:**  
- Services can consume unlimited resources
- Risk of resource exhaustion affecting other services
- No guaranteed minimum resources for critical services
- Potential for OOM kills without proper limits

**Recommendation:**  
Add resource constraints to all services:
```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 2G
    reservations:
      cpus: '0.25'
      memory: 512M
```

Suggested limits per service:
- **Prometheus**: limits 2GB RAM / 1 CPU, reservations 512MB / 0.25 CPU
- **Grafana**: limits 1GB RAM / 0.5 CPU, reservations 256MB / 0.25 CPU
- **Loki**: limits 2GB RAM / 1 CPU, reservations 512MB / 0.25 CPU
- **Promtail**: limits 512MB RAM / 0.5 CPU, reservations 128MB / 0.1 CPU
- **cAdvisor**: limits 512MB RAM / 0.5 CPU, reservations 128MB / 0.1 CPU

### 5. No Data Retention Policies
**Status:** Open  
**Priority:** Medium  
**Category:** Data Management

**Current State:**  
No retention policies configured for Prometheus or Loki data.

**Problem:**  
- Data will grow indefinitely
- Storage could fill up causing service failures
- Performance degradation over time
- Unnecessary historical data consuming resources

**Recommendation:**  

**Prometheus:**
```yaml
command:
  - '--config.file=/etc/prometheus/prometheus.yml'
  - '--storage.tsdb.retention.time=30d'
  - '--storage.tsdb.retention.size=10GB'
```

**Loki (add to loki.yml):**
```yaml
limits_config:
  retention_period: 744h  # 31 days
  
compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
```

### 6. Missing Health Checks
**Status:** Open  
**Priority:** Medium  
**Category:** Reliability

**Current State:**  
No health check definitions for any service.

**Problem:**  
- Docker/Swarm cannot detect service health automatically
- Failed services may remain in "running" state
- No automatic restart on health check failure
- Difficult to determine service status programmatically

**Recommendation:**  
Add health checks to all services:

**Prometheus:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Grafana:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

**Loki:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3100/ready"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 7. No Backup Strategy
**Status:** Open  
**Priority:** Medium  
**Category:** Data Protection

**Current State:**  
Named volumes are used but no backup configuration exists.

**Problem:**  
- Risk of data loss
- No disaster recovery plan
- Cannot restore to previous states
- Dashboards and configurations not protected

**Recommendation:**  
1. Implement automated volume backups using:
   - Docker volume plugins with backup capabilities
   - Scheduled backup jobs using volume mounts
   - Cloud storage integration (S3, Azure Blob, etc.)
2. Document backup and restore procedures
3. Test restore procedures regularly
4. Consider Grafana's built-in provisioning for dashboard as code
5. Store Prometheus alert rules in version control

### 8. Missing Prometheus Configuration Best Practices
**Status:** Open  
**Priority:** Medium  
**Category:** Configuration

**Current State:**  
Basic Prometheus configuration lacks several recommended settings.

**Problem:**  
- No external labels for federation/remote write
- Missing recommended command-line flags
- No configuration for remote write (if needed)
- Limited scrape configuration options

**Recommendation:**  
Enhance prometheus.yml:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'home-server'
    environment: 'production'

# Add alert rules
rule_files:
  - /etc/prometheus/alerts/*.yml

# Consider remote write for long-term storage
# remote_write:
#   - url: https://remote-storage/api/v1/write
```

Add command-line flags:
```yaml
command:
  - '--config.file=/etc/prometheus/prometheus.yml'
  - '--storage.tsdb.path=/prometheus'
  - '--storage.tsdb.retention.time=30d'
  - '--web.console.libraries=/usr/share/prometheus/console_libraries'
  - '--web.console.templates=/usr/share/prometheus/consoles'
  - '--web.enable-lifecycle'
```

## 🟢 Low Priority Issues

### 9. Missing Service Self-Monitoring
**Status:** Open  
**Priority:** Low  
**Category:** Observability

**Current State:**  
Monitoring services themselves are not being monitored comprehensively.

**Problem:**  
- No metrics from Loki service itself
- No metrics from Promtail service
- Limited visibility into monitoring stack health
- Cannot detect monitoring service issues proactively

**Recommendation:**  
1. Add Prometheus scrape configs for all monitoring services:
```yaml
- job_name: 'loki'
  static_configs:
    - targets: ['loki:3100']

- job_name: 'promtail'
  static_configs:
    - targets: ['promtail:9080']

- job_name: 'grafana'
  static_configs:
    - targets: ['grafana:3000']
```

2. Create Grafana dashboards for monitoring stack health
3. Set up alerts for monitoring service failures

### 10. No Service Documentation
**Status:** Open  
**Priority:** Low  
**Category:** Documentation

**Current State:**  
No README.md or documentation for the monitoring stack.

**Problem:**  
- Unclear setup instructions
- No troubleshooting guide
- Missing architecture documentation
- No dashboard import/export instructions
- Unclear access URLs and credentials

**Recommendation:**  
Create a comprehensive README.md including:
1. Architecture overview and service descriptions
2. Access information (URLs, default credentials)
3. Initial setup and configuration steps
4. Dashboard import/export procedures
5. Common troubleshooting scenarios
6. Backup and restore procedures
7. Scaling considerations
8. Integration with other stacks

### 11. Missing Log Parsing and Enrichment
**Status:** Open  
**Priority:** Low  
**Category:** Observability

**Current State:**  
Promtail collects logs but doesn't parse or enrich them.

**Problem:**  
- Logs are stored as raw text
- Difficult to filter and query efficiently
- No structured logging benefits
- Missing valuable metadata

**Recommendation:**  
Enhance promtail.yml with pipeline stages:
```yaml
scrape_configs:
  - job_name: docker-logs
    static_configs:
      - targets: ['localhost']
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*.log
    pipeline_stages:
      - json:
          expressions:
            log: log
            stream: stream
            time: time
      - labels:
          stream:
      - timestamp:
          source: time
          format: RFC3339Nano
      - output:
          source: log
```

### 12. Consider Adding Node Exporter
**Status:** Open  
**Priority:** Low  
**Category:** Observability

**Current State:**  
Only cAdvisor is collecting container metrics. No host-level metrics collection.

**Problem:**  
- Missing detailed host metrics (filesystem, network, system stats)
- Incomplete picture of system health
- Cannot track host-specific issues

**Recommendation:**  
Add Node Exporter service:
```yaml
node-exporter:
  image: prom/node-exporter:v1.7.0
  command:
    - '--path.rootfs=/host'
  volumes:
    - '/:/host:ro,rslave'
  networks:
    - default
  deploy:
    mode: global
    restart_policy:
      condition: on-failure
    labels:
      - prometheus-job=node-exporter
```

### 13. Grafana Provisioning
**Status:** Open  
**Priority:** Low  
**Category:** Configuration Management

**Current State:**  
Grafana configuration is manual through the UI.

**Problem:**  
- Dashboards not version controlled
- Data sources must be manually configured
- Difficult to replicate setup
- No infrastructure as code

**Recommendation:**  
Implement Grafana provisioning:
1. Create datasource provisioning files
2. Create dashboard provisioning files
3. Mount provisioning configs as volumes
4. Store dashboard JSON in repository

Example structure:
```
monitoring/
  grafana/
    provisioning/
      datasources/
        prometheus.yml
        loki.yml
      dashboards/
        default.yml
    dashboards/
      container-metrics.json
      logs-dashboard.json
```

---

## Implementation Priority

### Phase 1 (Critical - Do First)
1. Version Pinning (#1)
2. Missing Authentication & Security (#2)
3. Missing Alerting System (#3)

### Phase 2 (Important - Do Soon)
4. Resource Constraints (#4)
5. Data Retention Policies (#5)
6. Health Checks (#6)

### Phase 3 (Nice to Have - Do Later)
7. Backup Strategy (#7)
8. Prometheus Configuration Best Practices (#8)
9. Service Self-Monitoring (#9)
10. Service Documentation (#10)

### Phase 4 (Optional - Consider)
11. Log Parsing and Enrichment (#11)
12. Node Exporter Addition (#12)
13. Grafana Provisioning (#13)

---

## Contributing

When working on these improvements:
1. Create a separate branch for each improvement
2. Test thoroughly in a non-production environment
3. Update this document as issues are resolved
4. Document any configuration changes in the stack README
5. Consider backward compatibility when making changes
