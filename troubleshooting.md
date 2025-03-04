# Troubleshooting

## K3s Orphans
K3s cluster can lose qurom in case of orphan nodes If the nodes are not properly cleaned. This state requires manually running the following on the only server node that is left:
```shell
sudo su
export PATH=/usr/local/bin:$PATH
rm /var/lib/rancher/k3s/server/db/reset-flag

systemctl stop k3s
k3s server --cluster-reset --flannel-backend=host-gw --flannel-iface=tailscale0  --flannel-ipv6-masq
systemctl start k3s
```

## Storage

### ZFS Node Migration
The stateful resources that have ZFS-based persistent volumes are pinned to specific nodes. In case of node failure, these statefulset resources are stuck in pending state as they need to be started on the nodes where they were originally started on. We have configured Velero backups already for our statefulset resources and they can be used to recover the lost data and also start the resources on a different node.

Execute the following steps to recover data and start the stateful resources on a different node:
1. Add a ConfigMap needed by Velero to map old node to a new desired node:
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: change-pvc-node-selector-config
      namespace: backup
      labels:
        velero.io/plugin-config: ""
        velero.io/change-pvc-node-selector: RestoreItemAction
    data:
      <old node name>: <new node name>
    ```
    ```shell
    kubectl apply -f <configmap file>
    ```

2. Remove all the relevant data resources such as PVCs etc.
3. Restore the resources from a Velero backup.
    ```shell
    velero -n backup restore create <any name> --from-backup <backup name>
    ```

## Linux Partition Creation
In case you need to create a partition for the available disk space. You can execute the following steps:
1. Enter the `fdisk` console and perform the following operations.
   ```shell
   sudo fdisk /dev/<disk name>
   Command (m for help): n
   Partition number (<partition number range>): <partition number>
   First sector (<start sector end range>): <first sector>
   Last sector, +/-sectors or +/-size{K,M,G,T,P} (<start sector end range>): <end sector>
   Command (m for help): w
   ```
2. Check the creation of a new partition.
   ```shell
   lsblk /dev/<disk name>
   ```