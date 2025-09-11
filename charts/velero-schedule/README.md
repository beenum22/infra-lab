# Velero Schedule Helm Chart

This Helm chart deploys Velero Schedule resources for automated Kubernetes cluster backups.

## Installation

```bash
helm install my-backup-schedule ./charts/velero-schedule -n velero
```

## Configuration

### Basic Usage

```yaml
schedules:
  - name: daily-apps-backup
    schedule: "0 2 * * *"  # Daily at 2 AM
    template:
      ttl: "168h"  # 7 days retention
      includedNamespaces:
        - apps
        - default
      snapshotVolumes: true

  - name: weekly-full-backup
    schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
    template:
      ttl: "720h"  # 30 days retention
      snapshotVolumes: true
      labelSelector:
        matchLabels:
          backup: "weekly"
```

### Values Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `schedules` | List of backup schedules to create | `[]` |
| `schedules[].name` | Name of the schedule | Required |
| `schedules[].schedule` | Cron expression for backup timing | `global.defaultSchedule` |
| `schedules[].template.ttl` | Backup retention time | `global.defaultTtl` |
| `schedules[].template.includedNamespaces` | Namespaces to backup | `[]` |
| `schedules[].template.excludedNamespaces` | Namespaces to exclude | `[]` |
| `schedules[].template.snapshotVolumes` | Whether to snapshot volumes | `true` |
| `global.storageLocation` | Default storage location | `"default"` |
| `global.volumeSnapshotLocations` | Default volume snapshot locations | `["default"]` |
| `global.defaultTtl` | Default backup retention | `"168h"` |
| `global.defaultSchedule` | Default cron schedule | `"0 2 * * *"` |

### Advanced Configuration

```yaml
schedules:
  - name: app-specific-backup
    schedule: "0 1 * * *"
    template:
      ttl: "336h"  # 14 days
      includedNamespaces:
        - production
      labelSelector:
        matchLabels:
          app.kubernetes.io/name: "my-app"
      hooks:
        resources:
          - name: database-backup
            includedNamespaces:
              - production
            excludedResources:
              - secrets
            pre:
              - exec:
                  container: postgres
                  command:
                    - /bin/bash
                    - -c
                    - "pg_dump mydb > /backup/dump.sql"
```

## Examples

### Daily Application Backup
```yaml
schedules:
  - name: daily-apps
    schedule: "0 2 * * *"
    template:
      includedNamespaces:
        - apps
        - monitoring
      ttl: "168h"
```

### Weekly Full Cluster Backup
```yaml
schedules:
  - name: weekly-full
    schedule: "0 3 * * 0"
    template:
      ttl: "720h"
      snapshotVolumes: true
```

## Prerequisites

- Velero must be installed and configured in the cluster
- Storage location and volume snapshot location must be configured
- Appropriate RBAC permissions for Velero

## Troubleshooting

1. **Schedule not running**: Check Velero controller logs
2. **Backup failures**: Verify storage location configuration
3. **Permission issues**: Ensure Velero has proper RBAC permissions