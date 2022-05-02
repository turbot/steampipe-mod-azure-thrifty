variable "sql_database_age_max_days" {
  type        = number
  description = "The maximum number of days databases are allowed to run."
  default     = 90
}

variable "sql_database_age_warning_days" {
  type        = number
  description = "The number of days databases can be running before sending a warning."
  default     = 30
}

locals {
  sql_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/SQL"
  })
}

benchmark "sql" {
  title         = "SQL Checks"
  description   = "Thrifty developers checks long running SQL databases should be associated with reserved capacity."
  documentation = file("./controls/docs/sql.md")
  children = [
    control.sql_database_long_running_reserved_capacity
  ]

  tags = merge(local.sql_common_tags, {
    type = "Benchmark"
  })
}

control "sql_database_long_running_reserved_capacity" {
  title       = "Long running SQL databases should have reserved capacity purchased for them"
  description = "Purchasing reserved capacity for long running SQL databases provides significant discounts."
  severity    = "low"

  sql = <<-EOT
    select
      db.id as resource,
      case
        when date_part('day', now() - creation_date) > $1 then 'alarm'
        when date_part('day', now() - creation_date) > $2 then 'info'
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
      db.name != 'master'
      and db.subscription_id = sub.subscription_id;
  EOT

  param "sql_database_age_max_days" {
    description = "The maximum number of days databases are allowed to run."
    default     = var.sql_database_age_max_days
  }

  param "sql_database_age_warning_days" {
    description = "The number of days databases can be running before sending a warning."
    default     = var.sql_database_age_warning_days
  }

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}
