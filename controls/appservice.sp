locals {
  appservice_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/AppService"
  })
}

benchmark "appservice" {
  title         = "AppService Checks"
  description   = "Thrifty developers eliminate unused and under-utilized AppService resources."
  documentation = file("./controls/docs/appservice.md")
  children = [
    control.app_service_plan_unused
  ]

  tags = merge(local.appservice_common_tags, {
    type = "Benchmark"
  })
}

control "app_service_plan_unused" {
  title       = "Unused AppService plans should be removed"
  description = "AppService plans that have been not attached to any apps should be reviewed as these plans are billed hourly, you should consider reconfiguring or deleting them if you don't intend to use them anymore."
  severity    = "low"

  sql = <<-EOT
    select
      p.id as resource,
    case
      when apps is null then 'alarm'
      else 'ok'
    end as status,
    case
      when apps is null then p.title || ' is useless.'
      else p.title || ' has apps attached.'
    end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "p.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_app_service_plan as p
      left join azure_subscription as sub on sub.subscription_id = p.subscription_id;
  EOT

  tags = merge(local.appservice_common_tags, {
    class = "unused"
  })
}
