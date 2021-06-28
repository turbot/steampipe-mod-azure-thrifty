locals {
  compute_common_tags = merge(local.thrifty_common_tags, {
    service = "compute"
  })
}

benchmark "compute" {
  title         = "Compute Checks"
  description   = "Thrifty developers checks compute tables have stale data or not."
  #documentation = file("./controls/docs/compute.md") #TODO
  tags          = local.compute_common_tags
  children = [
    control.compute_disk_high_iops,
    control.compute_disk_attached_stopped_instance,
    control.compute_disk_large,
    control.compute_disk_standard_hdd,
    control.compute_snapshot_age_90,
    control.compute_sql_database_age_90,
    control.compute_unattached_disk,
    control.compute_unattached_ip_address,
    control.compute_virtual_machine_large,
    control.compute_virtual_machine_long_running,
  ]
}

control "compute_disk_high_iops" {
  title       = "Compute disks with high IOPS should be reviewed"
  description = "High IOPS io1 and io2 volumes are costly and usage should be reviewed."
  severity    = "low"

  sql = <<-EOT
    select
      disk.id as resource,
      case
        when disk_iops_read_write > 3200 then 'alarm'
        else 'ok'
      end as status,
      disk.title || ' has ' || disk_iops_read_write || ' IOPS.'
      as reason,
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

control "compute_disk_attached_stopped_instance" {
  title       = "Disks attached to stopped instances should be reviewed"
  description = "Instances that are stopped may no longer need any disks attached."
  severity    = "low"

  sql = <<-EOT
    select
      disk.unique_id as resource,
      case
        when disk_state = 'Unattached' then 'skip'
        when vm.power_state = 'running' then 'ok'
        else 'alarm'
      end as status,
      case
        when disk_state = 'Unattached' then disk.name|| ' not attached to instance.'
        when vm.power_state = 'running' then disk.name || ' attached to running instance.'
        else disk.name || ' not attached to running instance.'
      end as reason,
      disk.resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk as disk
      left join azure_compute_virtual_machine as vm on lower(vm.id) = lower(disk.managed_by),
      azure_subscription sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_large" {
  title       = "Compute disks with over 100 GB should be resized if too large"
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

control "compute_disk_standard_hdd" {
  title       = "Compute disk type should be standard HDD"
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
    class = "deprecated"
  })
}

control "compute_sql_database_age_90" {
  title       = "Old sql database should be reviewed"
  description = "Old sql database should be reviewed and checked if needed."
  severity    = "low"

  sql = <<-EOT
    select
      s.id as resource,
      case
        when date_part('day', now()-creation_date) > 90 then 'alarm'
        when date_part('day', now()-creation_date) > 30 then 'info'
        else 'ok'
      end as status,
      s.title || ' has been in use for ' || date_part('day', now()-creation_date) || ' days.' as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_sql_database as s,
      azure_subscription sub
    where
      sub.subscription_id = s.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_unattached_disk" {
  title       = "Unattached compute disks should be removed"
  description = "Unattached compute disks are charged by GCP, they should be removed unless there is a business need to retain them."
  severity    = "low"

  sql = <<-EOT
    select
      disk.unique_id as resource,
      case
        when disk_state = 'Unattached' then 'alarm'
        else 'ok'
      end as status,
      case
        when disk_state = 'Unattached' then  disk.title || ' has no attachments.'
        else disk.title || ' has attachments.'
      end as reason,
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

control "compute_unattached_ip_address" {
  title       = "Unattached external IP addresses should be removed"
  description = "Unattached external IPs are charged, they should be released."
  severity    = "low"

  sql = <<-EOT
    select
      ip.name as resource,
      case
        when ip_configuration_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when ip_configuration_id is null then ip.title  || ' has no association.'
        else ip.title || ' associated with ' || ip_configuration_id || '.'
      end as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_public_ip ip,
      azure_subscription sub
    where
      sub.subscription_id = ip.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_virtual_machine_large" {
  title         = "Virtual machines greater than 12xlarge should be reviewed"
  description   = "Large virtual machines are unusual, expensive and should be reviewed."
  severity      = "low"

  sql = <<-EOT
    select
      vm_id as resource,
      case
        when size not in ('Standard_D8s_v3', 'Standard_DS3_v3') then 'alarm'
        else 'ok'
      end as status,
      vm.title || ' has type ' || size || '.'
      as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_compute_virtual_machine vm,
      azure_subscription sub
    where
      sub.subscription_id = vm.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_virtual_machine_long_running" {
  title       = "Long virtual machines should be reviewed"
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
