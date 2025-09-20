# Velero Backup Restore Helm Chart

This Helm chart provides automated backup and restore for Kubernetes resources using Velero with focus on PVC volume snapshots.

## Installation

```bash
helm install my-backup-restore ./charts/velero-backup-restore -n backup
```

## Configuration

### Basic Usage

```yaml
schedule:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  namespace: "apps"
  retention: "7d"  # 7 days retention (supports "7d", "168h", or plain numbers)
  includedResources:
    - persistentvolumeclaims
  snapshotVolumes: true
  snapshotMoveData: true

labelSelector:
  app.kubernetes.io/name: "my-app"
```

### Retention Configuration

The chart supports flexible retention formats:

- **Days**: `"7d"`, `"14d"`, `"30d"` - automatically converted to hours
- **Hours**: `"168h"`, `"336h"`, `"720h"` - used directly
- **Plain numbers**: `168`, `336` - treated as hours

Examples:
```yaml
schedule:
  retention: "7d"    # 7 days = 168 hours
  retention: "48h"   # 48 hours directly
  retention: 72      # 72 hours
```

### Values Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `schedule.enabled` | Enable scheduled backup | `false` |
| `schedule.schedule` | Cron expression for backup timing | `"0 2 * * *"` |
| `schedule.namespace` | Target namespace for backup | `"apps"` |
| `schedule.retention` | Backup retention (supports days/hours) | `"7d"` |
| `schedule.includedResources` | Resource types to include | `["persistentvolumeclaims"]` |
| `schedule.snapshotVolumes` | Create volume snapshots | `true` |
| `schedule.snapshotMoveData` | Move snapshot data to object storage | `true` |
| `schedule.storageLocation` | Storage location name | `"default"` |
| `schedule.volumeSnapshotLocation` | Volume snapshot location | `"default"` |
| `restore.enabled` | Enable restore resource | `false` |
| `restore.backupName` | Backup name to restore from | `""` |
| `labelSelector` | Label selector for targeting resources | `{}` |
| `global.storageLocation` | Global default storage location | `"default"` |
| `global.volumeSnapshotLocation` | Global default volume snapshot location | `"default"` |
| `global.defaultSchedule` | Global default cron schedule | `"0 2 * * *"` |
| `global.defaultRetention` | Global default retention | `"7d"` |

## Examples

### Daily PVC Backup with 14-day retention
```yaml
schedule:
  enabled: true
  schedule: "0 2 * * *"
  namespace: "production"
  retention: "14d"  # 14 days
  includedResources:
    - persistentvolumeclaims
  snapshotVolumes: true
  snapshotMoveData: true

labelSelector:
  app.kubernetes.io/name: "database"
```

### Short-term backup with hourly retention
```yaml
schedule:
  enabled: true
  schedule: "0 */6 * * *"  # Every 6 hours
  namespace: "apps"
  retention: "48h"  # 48 hours
  includedResources:
    - persistentvolumeclaims
    - configmaps
    - secrets
```

### Restore from backup
```yaml
schedule:
  enabled: false

restore:
  enabled: true
  backupName: "my-backup-20231201-120000"

labelSelector:
  app.kubernetes.io/name: "my-app"
```

## Prerequisites

- **Velero v1.12+** must be installed and configured in the cluster with:
  - Node agent enabled (`--use-node-agent`)
  - CSI features enabled (`--features=EnableCSI`)
  - Backup storage location configured (S3-compatible)
  - Volume snapshot location configured
- **OpenEBS Velero plugin** installed for ZFS snapshot support
- Appropriate RBAC permissions for Velero operations

## Troubleshooting

1. **Schedule not running**: Check Velero controller logs
2. **Backup failures**: Verify storage location configuration
3. **Permission issues**: Ensure Velero has proper RBAC permissions