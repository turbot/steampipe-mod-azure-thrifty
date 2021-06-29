locals {
  compute_common_tags = merge(local.thrifty_common_tags, {
    service = "compute"
  })
}

benchmark "compute" {
  title         = "Compute Checks"
  description   = "Thrifty developers eliminate unused and under-utilized Compute resources."
  documentation = file("./controls/docs/compute.md")
  tags          = local.compute_common_tags
  children = [
    control.compute_disk_attached_stopped_instance,
    control.compute_disk_high_iops,
    control.compute_disk_large,
    control.compute_disk_low_iops,
    control.compute_disk_snapshot_storage_standard,
    control.compute_disk_standard_hdd,
    control.compute_disk_unattached,
    control.compute_snapshot_age_90,
    control.compute_virtual_machine_long_running,
  ]
}

control "compute_disk_attached_stopped_instance" {
  title       = "Disks attached to stopped instances should be reviewed"
  description = "Instances that are stopped may no longer need any disks attached."
  severity    = "low"

  sql = <<-EOT
    with attached_disk_with_vm as (
      select
        power_state as instance_state,
        os_disk_name,
        jsonb_agg(data_disk ->> 'name') as data_disk_names
      from
        azure_compute_virtual_machine left join jsonb_array_elements(data_disks) as data_disk on true
      group by name, os_disk_name, power_state
    )
    select
      d.id as resource,
      case
        when d.disk_state = 'Unattached' then 'skip'
        when m.instance_state = 'running' then 'ok'
        else 'alarm'
      end as status,
      case
        when d.disk_state = 'Unattached' then d.name || ' not attached to virtual machine.'
        when m.instance_state = 'running' then d.name || ' attached to running virtual machine.'
        else d.name || ' not attached to running virtual machine.'
      end as reason,
      d.resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk as d
      left join attached_disk_with_vm as m on (d.name = m.os_disk_name or m.data_disk_names ?| array[d.name])
      left join azure_subscription as sub on sub.subscription_id = d.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_high_iops" {
  title       = "Disks with high IOPS should be reviewed"
  description = "High IOPS disks are costly and usage should be reviewed."
  severity    = "low"

  sql = <<-EOT
    select
      disk.id as resource,
      case
        when disk_iops_read_write > 32000 then 'alarm'
        else 'ok'
      end as status,
      disk.title || ' has ' || disk_iops_read_write || ' IOPS.'
      as reason,
      disk.resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk disk,
      azure_subscription sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_large" {
  title       = "Disks with over 100 GB should be resized if too large"
  description = "Large compute disks are unusual, expensive and should be reviewed."
  severity    = "low"

  sql = <<-EOT
    select
      disk.unique_id as resource,
      case
        when disk_size_gb <= 100 then 'ok'
        else 'alarm'
      end as status,
      disk.title || ' is ' || disk_size_gb || 'GB.' as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk disk,
      azure_subscription sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_low_iops" {
  title       = "Disks with low IOPS should be reviewed"
  description = "Compute disks with low IOPS should be reviewed."
  severity    = "low"

  sql = <<-EOT
    select
      disk.id as resource,
      case
        when disk_iops_read_write <= 3000 then 'alarm'
        else 'ok'
      end as status,
      disk.title || ' has ' || disk_iops_read_write || ' IOPS.' as reason,
      disk.resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk disk,
      azure_subscription sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_snapshot_storage_standard" {
  title       = "Disks snapshots storage type should be standard"
  description = "Use standard storage type for compute disks snapshots to save cost."
  severity    = "low"

  sql = <<-EOT
    select
      ss.id as resource,
      case
        when ss.sku_tier = 'Standard' then 'ok'
        else 'alarm'
      end as status,
      case
        when ss.sku_tier = 'Standard' then ss.title || ' has storage type ' || ss.sku_tier || '.'
        else ss.title || ' has storage type ' || ss.sku_tier || '.'
      end as reason,
      ss.resource_group,
      sub.display_name as subscription
    from
      azure_compute_snapshot ss,
      azure_subscription sub
    where
      ss.subscription_id = sub.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_standard_hdd" {
  title       = "Disk type should be standard HDD"
  description = "Use standard HDD for backup and non critical, infrequent access."
  severity    = "low"

  sql = <<-EOT
    select
      disk.id as resource,
      case
        when disk.sku_name = 'Standard_LRS' then 'ok'
        else 'alarm'
      end as status,
      case
        when disk.sku_name = 'Standard_LRS' then disk.title || ' has type ' || disk.sku_tier || ' HDD.'
        else disk.title || ' has type ' || disk.sku_tier || ' SSD.'
      end as reason,
      disk.resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk disk,
      azure_subscription sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_unattached" {
  title       = "Unused disks should be removed"
  description = "Unattached compute disks are charged by Azure, they should be removed unless there is a business need to retain them."
  severity    = "low"

  sql = <<-EOT
    select
      disk.id as resource,
      case
        when disk.disk_state = 'Unattached' then 'alarm'
        else 'ok'
      end as status,
      case
        when disk.disk_state = 'Unattached' then disk.title || ' has no attachments.'
        else disk.title || ' has attachments.'
      end as reason,
      disk.resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk disk,
      azure_subscription sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}

control "compute_snapshot_age_90" {
  title       = "Snapshots created over 90 days ago should be deleted if not required"
  description = "Old snapshots are likely unneeded and costly to maintain."
  severity    = "low"

  sql = <<-EOT
    select
      s.unique_id as resource,
      case
        when time_created > current_timestamp - interval '90 days' then 'ok'
        else 'alarm'
      end as status,
      s.title || ' created at ' || time_created || ' (' || date_part('day', now()-time_created) || ' days).'
      as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_compute_snapshot s,
      azure_subscription sub
    where
      sub.subscription_id = s.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}

control "compute_virtual_machine_long_running" {
  title       = "Long running virtual machines should be reviewed"
  description = "Virtual machines should ideally be ephemeral and rehydrated frequently, check why these instances have been running for so long."
  severity    = "low"

  sql = <<-EOT
    select
      vm.id as resource,
      case
        when date_part('day', now() - (s ->> 'time') :: timestamptz) > 90 then 'alarm'
        else 'ok'
      end as status,
      vm.title || ' has been running for ' || date_part('day', now() - (s ->> 'time') :: timestamptz) || ' days.'
      as reason,
      vm.resource_group,
      sub.display_name as subscription
    from
      azure_compute_virtual_machine vm,
      jsonb_array_elements(statuses) as s,
      azure_subscription sub
    where
      vm.power_state in ('running', 'starting') and s ->> 'time' is not null;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}