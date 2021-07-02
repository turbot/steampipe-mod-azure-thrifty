locals {
  sql_common_tags = merge(local.thrifty_common_tags, {
    service = "sql"
  })
}

benchmark "sql" {
  title         = "SQL Checks"
  description   = "Thrifty developers checks long running SQL databases should be associated with reserved capacity."
  documentation = file("./controls/docs/sql.md")
  tags          = local.sql_common_tags
  children = [
    control.sql_database_long_running_reserved_capacity,
  ]
}

control "sql_database_long_running_reserved_capacity" {
  title       = "Long running SQL databases should have reserved capacity purchased for them"
  description = "Purchasing reserved capacity for long running SQL databases provides significant discounts."
  severity    = "low"

  sql = <<-EOT
    select
      db.id as resource,
      case
        when date_part('day', now() - creation_date) > 90 then 'alarm'
        when date_part('day', now() - creation_date) > 30 then 'info'
        else 'ok'
      end as status,
      db.title || ' has been in use for ' || date_part('day', now() - creation_date) || ' day(s).'
      as reason,
      db.resource_group,
      sub.display_name as subscription
    from
      azure_sql_database as db,
      azure_subscription as sub
    where
      db.name != 'master' and db.subscription_id = sub.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}
