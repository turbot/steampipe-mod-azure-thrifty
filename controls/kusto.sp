locals {
  kusto_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/DataExplorer"
  })
}

benchmark "kusto" {
  title         = "DataExplorer Checks"
  description   = "Thrifty developers eliminate unused and under-utilized DataExplorer resources."
  documentation = file("./controls/docs/kusto.md")
  children = [
    control.kusto_cluster_without_autoscaling
  ]

  tags = merge(local.kusto_common_tags, {
    type = "Benchmark"
  })
}

control "kusto_cluster_without_autoscaling" {
  title       = "Kusto cluster should use autoscaling policy"
  description = "Kusto cluster should use autoscaling policy to improve service performance in a cost-efficient way."
  severity    = "low"

  sql = <<-EOT
    select
      c.id as resource,
      case
        when (optimized_autoscale -> 'isEnabled')::bool then 'ok'
        else 'alarm'
      end as status,
      case
        when (optimized_autoscale -> 'isEnabled')::bool then c.name || ' has autoscaling enabled.'
        else c.name || ' has autoscaling disabled.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "c.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_kusto_cluster as c
      left join azure_subscription as sub on sub.subscription_id = c.subscription_id;
  EOT

  tags = merge(local.kusto_common_tags, {
    class = "managed"
  })
}
