locals {
  network_common_tags = merge(local.thrifty_common_tags, {
    service = "network"
  })
}

benchmark "network" {
  title         = "Network Checks"
  description   = "Thrifty developers eliminate unused IP addresses and virtual network gateways."
  documentation = file("./controls/docs/network.md")
  tags          = local.network_common_tags
  children = [
    control.network_public_ip_unattached,
    control.virtual_network_gateway_unused,
  ]
}

control "network_public_ip_unattached" {
  title       = "Unattached external IP addresses should be removed"
  description = "Unattached external IPs cost money and should be released."
  severity    = "low"

  sql = <<-EOT
    select
      ip.id as resource,
      case
        when ip.ip_configuration_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when ip.ip_configuration_id is null then ip.title  || ' has no associations.'
        else ip.title || ' associated with network interface ' || split_part(ip.ip_configuration_id, '/', 9) || '.'
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

control "virtual_network_gateway_unused" {
  title       = "Unused virtual network gateways should be removed"
  description = "Virtual network gateways that have been idle/no connection for more than 90 days should be reviewed as these gateways are billed hourly, you should consider reconfiguring or deleting them if you don't intend to use them anymore."
  severity    = "low"

  sql = <<-EOT
    select
      gateway.id as resource,
      case
        when gateway_connections is null then 'alarm'
        else 'ok'
      end as status,
      case
        when gateway_connections is null then gateway.title || ' has no connections.'
        else gateway.title || ' has connections.'
      end as reason,
      gateway.resource_group,
      sub.display_name as subscription
    from
      azure_virtual_network_gateway as gateway,
      azure_subscription as sub
    where
      sub.subscription_id = gateway.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}