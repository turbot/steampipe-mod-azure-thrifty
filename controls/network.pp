locals {
  network_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/Network"
  })
}

benchmark "network" {
  title         = "Network Checks"
  description   = "Thrifty developers eliminate unused IP addresses, virtual network gateways, and optimize Application Gateway configurations."
  documentation = file("./controls/docs/network.md")
  children = [
    control.network_public_ip_unattached,
    control.virtual_network_gateway_unused,
    control.network_private_endpoint_unused,
    control.network_application_gateway_optimization,
    control.network_load_balancer_rules_optimization
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

control "network_application_gateway_optimization" {
  title       = "Application Gateway SKU and capacity should be optimized"
  description = "Application Gateways should use autoscaling when supported by the SKU tier, and fixed capacity should be reviewed for optimization opportunities."
  severity    = "low"

  sql = <<-EOT
    select
      ag.id as resource,
      case
        when ag.autoscale_configuration is not null then 'ok'
        when ag.sku->>'tier' in ('Standard_v2', 'WAF_v2') and ag.autoscale_configuration is null then 'alarm'
        when (ag.sku->>'capacity')::int > 2 and ag.autoscale_configuration is null then 'alarm'
        else 'ok'
      end as status,
      case
        when ag.autoscale_configuration is not null then ag.name || ' has autoscaling enabled with min capacity ' || (ag.autoscale_configuration->>'minCapacity') || ' and max capacity ' || (ag.autoscale_configuration->>'maxCapacity') || '.'
        when ag.sku->>'tier' in ('Standard_v2', 'WAF_v2') then ag.name || ' uses ' || (ag.sku->>'tier') || ' tier which supports autoscaling but it is not enabled.'
        when (ag.sku->>'capacity')::int > 2 and ag.autoscale_configuration is null then ag.name || ' has high fixed capacity (' || (ag.sku->>'capacity') || ') without autoscaling.'
        else ag.name || ' has appropriate capacity configuration.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "ag.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_application_gateway as ag,
      azure_subscription as sub
    where
      sub.subscription_id = ag.subscription_id
      and ag.operational_state = 'Running';
  EOT

  tags = merge(local.network_common_tags, {
    class = "optimization"
  })
}

control "network_load_balancer_rules_optimization" {
  title       = "Standard load balancer rules should be optimized"
  description = "Standard SKU load balancers with more than 5 rules should be reviewed for optimization opportunities, as too many rules can lead to management complexity and potential performance impacts."
  severity    = "low"

  sql = <<-EOT
    with lb_rule_counts as (
      select 
        load_balancer_name,
        count(*) as rule_count,
        array_agg(name) as rule_names,
        subscription_id,
        resource_group
      from 
        azure_lb_rule
      group by 
        load_balancer_name,
        subscription_id,
        resource_group
    )
    select 
      lb.id as resource,
      case
        when lb.sku_name = 'Standard' and rc.rule_count > 5 then 'alarm'
        else 'ok'
      end as status,
      case
        when lb.sku_name = 'Standard' and rc.rule_count > 5 then lb.name || ' (Standard SKU) has ' || rc.rule_count || ' rules (' || array_to_string(rc.rule_names, ', ') || ').'
        when lb.sku_name = 'Standard' then lb.name || ' (Standard SKU) has ' || coalesce(rc.rule_count, 0) || ' rules.'
        else lb.name || ' is not a Standard SKU load balancer.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "lb.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from 
      azure_lb as lb
      left join lb_rule_counts as rc on 
        lb.name = rc.load_balancer_name 
        and lb.subscription_id = rc.subscription_id 
        and lb.resource_group = rc.resource_group,
      azure_subscription as sub
    where
      sub.subscription_id = lb.subscription_id;
  EOT

  tags = merge(local.network_common_tags, {
    class = "optimization"
  })
}