## Thrifty Compute Benchmark

Thrifty developers eliminate their unused and under-utilized compute instances.
This benchmark focuses on finding resources that have not been restarted
recently, are using very virtual machine type, virtual machine sizes, have old snapshots, and have
unused disks and IP addresses.

### Default Thresholds

- [Disks that are large (> 100 GB)]
- [Virtual machine types that are too big (> 12xlarge)]
- [Long running virtual machines threshold (90 Days)]
- [Snapshot age threshold (90 Days)]
