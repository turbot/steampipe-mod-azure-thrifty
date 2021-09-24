## Thrifty Compute Benchmark

Thrifty developers eliminate their unused and under-utilized compute instances. This benchmark focuses on finding resources that have not been restarted recently, have old snapshots, have high disk IOPS and have large, unused or inactive disks.

## Variables

| Variable | Description | Default |
| - | - | - |
| compute_disk_max_iops | The maximum IOPS allowed for disks. | 2000 IOPS |
| compute_disk_max_size_gb | The maximum size in GB allowed for disks. | 100 GB |
| compute_running_vm_age_max_days | The maximum number of days a virtual machine is allowed to run. | 90 days |
| compute_snapshot_age_max_days | The maximum number of days a snapshot can be retained. | 90 days |
