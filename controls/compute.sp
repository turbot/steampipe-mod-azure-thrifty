variable "compute_disk_iops_high" {
  type        = number
  description = "The maximum IOPS allowed for disks."
}

variable "compute_disk_max_size_gb" {
  type        = number
  description = "The maximum size (GB) allowed for disks."
}

variable "compute_running_vm_age_max_days" {
  type        = number
  description = "The maximum number of days a virtual machine is allowed to run."
}

variable "compute_snapshot_age_max_days" {
  type        = number
  description = "The maximum number of days a snapshot can be retained."
}

variable "compute_vm_avg_cpu_utilization_low" {
  type        = number
  description = "The average CPU utilization required for virtual machines to be considered infrequently used. This value should be lower than compute_vm_avg_cpu_utilization_high."
}

variable "compute_vm_avg_cpu_utilization_high" {
  type        = number
  description = "The average CPU utilization required for virtual machines to be considered frequently used. This value should be higher than compute_vm_avg_cpu_utilization_low."
}

variable "compute_disk_avg_read_write_ops_low" {
  type        = number
  description = "The number of average read/write ops required for disks to be considered infrequently used. This value should be lower than compute_disk_avg_read_write_ops_high."
}

variable "compute_disk_avg_read_write_ops_high" {
  type        = number
  description = "The number of average read/write ops required for disks to be considered frequently used. This value should be higher than compute_disk_avg_read_write_ops_low."
}

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
    control.compute_disk_attached_stopped_virtual_machine,
    control.compute_disk_high_iops,
    control.compute_disk_large,
    control.compute_disk_low_usage,
    control.compute_disk_snapshot_storage_standard,
    control.compute_disk_unattached,
    control.compute_snapshot_max_age,
    control.compute_virtual_machine_long_running,
    control.compute_virtual_machine_low_utilization,
  ]
}

control "compute_disk_attached_stopped_virtual_machine" {
  title       = "Disks attached to stopped virtual machines should be reviewed"
  description = "Virtual machines that are stopped may no longer need any disks attached."
  severity    = "low"

  sql = <<-EOT
    with attached_disk_with_vm as (
      select
        power_state as virtual_machine_state,
        os_disk_name,
        jsonb_agg(data_disk ->> 'name') as data_disk_names
      from
        azure_compute_virtual_machine
        left join jsonb_array_elements(data_disks) as data_disk on true
      group by name, os_disk_name, power_state
    )
    select
      d.id as resource,
      case
        when d.disk_state = 'Unattached' then 'skip'
        when m.virtual_machine_state = 'running' then 'ok'
        else 'alarm'
      end as status,
      case
        when d.disk_state = 'Unattached' then d.name || ' not attached to virtual machine.'
        when m.virtual_machine_state = 'running' then d.name || ' attached to running virtual machine.'
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
  title       = "Disks with high IOPS should be resized if too large"
  description = "High IOPS disks are costly and usage should be reviewed."
  severity    = "low"

  sql = <<-EOT
    select
      disk.id as resource,
      case
        when disk_iops_read_write > $1 then 'alarm'
        else 'ok'
      end as status,
      disk.title || ' has ' || disk_iops_read_write || ' IOPS.'
      as reason,
      disk.resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk as disk,
      azure_subscription as sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  param "compute_disk_iops_high" {
    description = "The maximum IOPS allowed for disks."
    default     = var.compute_disk_iops_high
  }

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_large" {
  title       = "Disks should be resized if too large"
  description = "Large disks are unusual, expensive and should be reviewed."
  severity    = "low"

  sql = <<-EOT
    select
      disk.unique_id as resource,
      case
        when disk_size_gb <= $1 then 'ok'
        else 'alarm'
      end as status,
      disk.title || ' is ' || disk_size_gb || ' GB.' as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_compute_disk as disk,
      azure_subscription as sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  param "compute_disk_max_size_gb" {
    description = "The maximum size (GB) allowed for disks."
    default     = var.compute_disk_max_size_gb
  }

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_snapshot_storage_standard" {
  title       = "Disks should use standard snapshots"
  description = "Use standard storage instead of premium storage for managed disk snapshots to save 60% on costs."
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
      azure_compute_snapshot as ss,
      azure_subscription as sub
    where
      ss.subscription_id = sub.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_disk_unattached" {
  title       = "Unused disks should be removed"
  description = "Unattached disks are charged by Azure, they should be removed unless there is a business need to retain them."
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
      azure_compute_disk as disk,
      azure_subscription as sub
    where
      sub.subscription_id = disk.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}

control "compute_snapshot_max_age" {
  title       = "Old snapshots should be deleted if not required"
  description = "Old snapshots are likely unneeded and costly to maintain."
  severity    = "low"

  sql = <<-EOT
    select
      s.unique_id as resource,
      case
        when time_created > current_timestamp - interval '$1 days' then 'ok'
        else 'alarm'
      end as status,
      s.title || ' created at ' || time_created || ' (' || date_part('day', now() - time_created) || ' days).'
      as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_compute_snapshot as s,
      azure_subscription as sub
    where
      sub.subscription_id = s.subscription_id;
  EOT

  param "compute_snapshot_age_max_days" {
    description = "The maximum number of days snapshots can be retained."
    default     = var.compute_snapshot_age_max_days
  }

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}

control "compute_virtual_machine_long_running" {
  title       = "Long running virtual machines should be reviewed"
  description = "Virtual machines should ideally be ephemeral and rehydrated frequently, check why these virtual machines have been running for so long."
  severity    = "low"

  sql = <<-EOT
    select
      vm.id as resource,
      case
        when date_part('day', now() - (s ->> 'time') :: timestamptz) > $1 then 'alarm'
        else 'ok'
      end as status,
      vm.title || ' has been running for ' || date_part('day', now() - (s ->> 'time') :: timestamptz) || ' days.'
      as reason,
      vm.resource_group,
      sub.display_name as subscription
    from
      azure_compute_virtual_machine as vm,
      jsonb_array_elements(statuses) as s,
      azure_subscription as sub
    where
      vm.power_state in ('running', 'starting')
      and s ->> 'time' is not null;
  EOT

  param "compute_running_vm_age_max_days" {
    description = "The maximum number of days virtual machines are allowed to run."
    default = var.compute_running_vm_age_max_days
  }

  tags = merge(local.compute_common_tags, {
    class = "deprecated"
  })
}

control "compute_virtual_machine_low_utilization" {
  title       = "Compute virtual machines with low CPU utilization should be reviewed"
  description = "Resize or eliminate under utilized virtual machines."
  severity    = "low"

  sql = <<-EOT
    with compute_virtual_machine_utilization as (
      select
        name,
        round(cast(sum(maximum)/count(maximum) as numeric), 1) as avg_max,
        count(maximum) as days
      from
        azure_compute_virtual_machine_metric_cpu_utilization_daily
      where
        date_part('day', now() - timestamp) <=30
      group by
        name
    )
    select
      v.id as resource,
      case
        when avg_max is null then 'error'
        when avg_max < $1 then 'alarm'
        when avg_max < $2 then 'info'
        else 'ok'
      end as status,
      case
        when avg_max is null then 'Monitor metrics not available for ' || v.title || '.'
        else v.title || ' averaging ' || avg_max || '% max utilization over the last ' || days || ' days.'
      end as reason,
      v.resource_group,
      sub.display_name as subscription
    from
      azure_compute_virtual_machine as v
      left join compute_virtual_machine_utilization as u on u.name = v.name
      left join azure_subscription as sub on sub.subscription_id = v.subscription_id;
  EOT

  param "compute_vm_avg_cpu_utilization_low" {
    description = "The average CPU utilization required for virtual machines to be considered infrequently used. This value should be lower than compute_vm_avg_cpu_utilization_high."
    default     = var.compute_vm_avg_cpu_utilization_low
  }

  param "compute_vm_avg_cpu_utilization_high" {
    description = "The average CPU utilization required for virtual machines to be considered frequently used. This value should be higher than compute_vm_avg_cpu_utilization_low."
    default     = var.compute_vm_avg_cpu_utilization_high
  }

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}

control "compute_disk_low_usage" {
  title       = "Compute disks with low usage should be reviewed"
  description = "Disks that are unused should be archived and deleted."
  severity    = "low"

  sql = <<-EOT
    with disk_usage as (
      select
        name,
        resource_group
        subscription_id,
        round(avg(max)) as avg_max,
        count(max) as days
      from
        (
          select
            name,
            resource_group,
            subscription_id,
            cast(maximum as numeric) as max
          from
            azure_compute_disk_metric_read_ops_daily
          where
            date_part('day', now() - timestamp) <= 30
          union all
          select
            name,
            resource_group,
            subscription_id,
            cast(maximum as numeric) as max
          from
            azure_compute_disk_metric_write_ops_daily
          where
            date_part('day', now() - timestamp) <= 30
        ) as read_and_write_ops
      group by
        name,
        resource_group,
        subscription_id
    )
    select
      d.id as resource,
      case
        when avg_max <= $1 then 'alarm'
        when avg_max <= $2 then 'info'
        else 'ok'
      end as status,
      d.name || ' averaging ' || avg_max || ' read and write ops over the last ' || days / 2 || ' days.' as reason,
      resource_group,
      display_name as subscription
    from
      disk_usage as u left join azure_compute_disk as d on u.name = d.name
      left join azure_subscription as sub on sub.subscription_id = d.subscription_id;
  EOT

  param "compute_disk_avg_read_write_ops_low" {
    description = "The number of average read/write ops required for disks to be considered infrequently used. This value should be lower than compute_disk_avg_read_write_ops_high."
    default     = var.compute_disk_avg_read_write_ops_low
  }

  param "compute_disk_avg_read_write_ops_high" {
    description = "The number of average read/write ops required for disks to be considered frequently used. This value should be higher than compute_disk_avg_read_write_ops_low."
    default     = var.compute_disk_avg_read_write_ops_high
  }

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}
