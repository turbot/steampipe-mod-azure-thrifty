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
    control.network_nat_gateway_unused,
    control.network_load_balancer_unused,
    control.application_gateway_without_autoscaling
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

  tags = merge(local.network_common_tags, {
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

  tags = merge(local.network_common_tags, {
    class = "unused"
  })
}

control "network_nat_gateway_unused" {
  title       = "Unused virtual NAT gateways should be removed"
  description = "Virtual NAT gateways that have been not attached to any subnets should be reviewed as these gateways are billed hourly, you should consider reconfiguring or deleting them if you don't intend to use them anymore."
  severity    = "low"

  sql = <<-EOT
    select
      gateway.id as resource,
      case
        when jsonb_array_length(subnets) > 0  then 'ok'
        else 'alarm'
      end as status,
      case
        when jsonb_array_length(subnets) > 0 then name || ' attached with subnets.'
        else name || ' not attached with subnets.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "gateway.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_nat_gateway as gateway,
      azure_subscription as sub
    where
      sub.subscription_id = gateway.subscription_id;
  EOT

  tags = merge(local.network_common_tags, {
    class = "unused"
  })
}

control "network_load_balancer_unused" {
  title       = "Unused virtual load balancer should be removed"
  description = "Virtual load balancers that have been not attached to any backend service instance should be reviewed as these load balancers are billed hourly, you should consider reconfiguring or deleting them if you don't intend to use them anymore."
  severity    = "low"

  sql = <<-EOT
    with lb_with_backend_pool as (
      select
        id
      from
        azure_lb,
        jsonb_array_elements(backend_address_pools) as p
      where
        jsonb_array_length(p -> 'properties' -> 'loadBalancerBackendAddresses') > 0
    )
    select
      lb.id as resource,
      case
        when p.id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when p.id is null then lb.title || ' is useless.'
        else lb.title || ' has no backend instance  attached.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "lb.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_lb as lb
      left join lb_with_backend_pool as p on p.id = lb.id,
      azure_subscription as sub
    where
      sub.subscription_id = lb.subscription_id;
  EOT

  tags = merge(local.network_common_tags, {
    class = "unused"
  })
}

control "application_gateway_without_autoscaling" {
  title       = "Application gateway should use autoscaling policy"
  description = "Application gateway should use autoscaling policy to improve service performance in a cost-efficient way."
  severity    = "low"

  sql = <<-EOT
    select
      lb.id as resource,
      case
        when autoscale_configuration is not null then 'ok'
        else 'alarm'
      end as status,
      case
        when autoscale_configuration is not null then lb.name || ' autoscaling enabled.'
        else lb.name || ' autoscaling disabled.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "lb.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_application_gateway as lb,
      azure_subscription as sub
    where
      sub.subscription_id = lb.subscription_id;
  EOT

  tags = merge(local.network_common_tags, {
    class = "managed"
  })
}
