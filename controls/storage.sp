locals {
  storage_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/Storage"
  })
}

benchmark "storage" {
  title         = "Storage Checks"
  description   = "Thrifty developers ensure their storage accounts have managed lifecycle policies."
  documentation = file("./controls/docs/storage.md")
  children = [
    control.storage_account_without_lifecycle_policy
  ]

  tags = merge(local.storage_common_tags, {
    type = "Benchmark"
  })
}

control "storage_account_without_lifecycle_policy" {
  title       = "Storage accounts should have lifecycle policies"
  description = "Storage accounts should have a lifecycle policy associated for data retention."
  severity    = "low"

  sql = <<-EOT
    select
      ac.id as resource,
      case
        when lifecycle_management_policy -> 'properties' -> 'policy' -> 'rules' is null then 'alarm'
        when lifecycle_management_policy -> 'properties' -> 'policy' -> 'rules' @> '[{"enabled":true}]' then 'ok'
        else 'alarm'
      end as status,
      case
        when lifecycle_management_policy -> 'properties' -> 'policy' -> 'rules' is null then ac.title || ' has no lifecycle policy.'
        when lifecycle_management_policy -> 'properties' -> 'policy' -> 'rules' @> '[{"enabled":true}]' then ac.title || ' has active lifecycle policy.'
        else ac.title || ' has no active lifecycle policy.'
      end as reason,
      resource_group,
      sub.display_name as subscription
    from
      azure_storage_account as ac
      left join azure_subscription as sub on ac.subscription_id = sub.subscription_id;
  EOT

  tags = merge(local.storage_common_tags, {
    class = "unused"
  })
}
