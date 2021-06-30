locals {
  network_common_tags = merge(local.thrifty_common_tags, {
    service = "network"
  })
}

benchmark "network" {
  title         = "Network Checks"
  description   = "Thrifty developers eliminate unused IP addresses."
  documentation = file("./controls/docs/network.md")
  tags          = local.network_common_tags
  children = [
    control.network_public_ip_unattached,
  ]
}

control "network_public_ip_unattached" {
  title       = "Unattached external IP addresses should be removed"
  description = "Unattached external IPs are charged, they should be released."
  severity    = "low"

  sql = <<-EOT
    select
      ip.id as resource,
      case
        when ip.ip_configuration_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when ip.ip_configuration_id is null then ip.title  || ' has no association.'
        else ip.title || ' associated with ' || split_part(ip.ip_configuration_id, '/', 8) || ' ' || split_part(ip.ip_configuration_id, '/', 9) || '.'
      end as reason,
      ip.resource_group,
      sub.display_name as subscription
    from
      azure_public_ip as ip,
      azure_subscription as sub
    where
      sub.subscription_id = ip.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}