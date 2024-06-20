locals {
  monitor_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/Monitor"
  })
}

benchmark "monitor" {
  title         = "Monitor Checks"
  description   = "Thrifty developers eliminate unused and under-utilized Monitor resources."
  documentation = file("./controls/docs/monitor.md")
  children = [
    control.log_profile_without_retention_policy
  ]

  tags = merge(local.monitor_common_tags, {
    type = "Benchmark"
  })
}

control "log_profile_without_retention_policy" {
  title       = "Log profiles should have lifecycle policies"
  description = "Log profiles should have a lifecycle policy associated for data retention."
  severity    = "low"

  sql = <<-EOT
    select
      p.id as resource,
      case
        when p.retention_policy ->> 'enabled' = 'true' then 'ok'
        else 'alarm'
      end as status,
      case
        when p.retention_policy ->> 'enabled' = 'true' then p.name || ' retention policy enabled.'
        else p.name || ' retention is not set.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "p.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_log_profile as p
      left join azure_subscription sub on sub.subscription_id = p.subscription_id;
  EOT

  tags = merge(local.monitor_common_tags, {
    class = "unused"
  })
}
