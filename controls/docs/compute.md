## Thrifty Compute Benchmark

Thrifty developers eliminate their unused and under-utilized compute instances. This benchmark focuses on finding resources that have not been restarted recently, have old snapshots, have high disk IOPS and have large, unused or inactive disks.

## Variables

| Variable | Description | Default |
| - | - | - |
| compute_disk_avg_read_write_ops_high | The number of average read/write ops required for disks to be considered frequently used. This value should be higher than `compute_disk_avg_read_write_ops_low`. | 500 |
| compute_disk_avg_read_write_ops_low | The number of average read/write ops required for disks to be considered infrequently used. This value should be lower than `compute_disk_avg_read_write_ops_high`. | 100 |
| compute_disk_max_iops | The maximum IOPS allowed for disks. | 2000 IOPS |
| compute_disk_max_size_gb | The maximum size (GB) allowed for disks. | 100 GB |
| compute_running_vm_age_max_days | The maximum number of days a virtual machines are allowed to run. | 90 days |
| compute_snapshot_age_max_days | The maximum number of days snapshots can be retained. | 90 days |
| compute_vm_avg_cpu_utilization_high | The average CPU utilization required for virtual machines to be considered frequently used. This value should be higher than `compute_vm_avg_cpu_utilization_low`. | 35% |
| compute_vm_avg_cpu_utilization_low | The average CPU utilization required for virtual machines to be considered infrequently used. This value should be lower than `compute_vm_avg_cpu_utilization_high`. | 20% |
