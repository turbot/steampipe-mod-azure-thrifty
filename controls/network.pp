locals {
  network_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/Network"
  })
}

benchmark "network" {
  title         = "Network Checks"
  description   = "Thrifty developers eliminate unused IP addresses and virtual network gateways."
  documentation = file("./controls/docs/network.md")
  children = [
    control.network_public_ip_unattached,
    control.virtual_network_gateway_unused,
    control.network_private_endpoint_unused
  ]

  tags = merge(local.network_common_tags, {
    type = "Benchmark"
  })
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
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "ip.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
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
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "gateway.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
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

control "network_private_endpoint_unused" {
  title       = "Unused private endpoints should be removed"
  description = "Private endpoints that have no service connections should be reviewed and removed if not needed, as they incur unnecessary costs."
  severity    = "low"

  sql = <<-EOT
    select
      pe.id as resource,
      case
        when pe.private_link_service_connections is null then 'alarm'
        else 'ok'
      end as status,
      case
        when pe.private_link_service_connections is null then pe.name || ' has no service connections.'
        else pe.name || ' has service connections.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "pe.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_private_endpoint as pe,
      azure_subscription as sub
    where
      sub.subscription_id = pe.subscription_id;
  EOT

  tags = merge(local.compute_common_tags, {
    class = "unused"
  })
}