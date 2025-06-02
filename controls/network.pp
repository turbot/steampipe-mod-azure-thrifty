locals {
  network_common_tags = merge(local.azure_thrifty_common_tags, {
    service = "Azure/Network"
  })
}

benchmark "network" {
  title         = "Network Checks"
  description   = "Thrifty developers eliminate unused network resources like IP addresses and gateways, ensure proper backend configurations for load balancers, and enable Application Gateway autoscaling when supported."
  documentation = file("./controls/docs/network.md")
  children = [
    control.network_application_gateway_with_autoscaling_disabled,
    control.network_load_balancer_with_duplicate_rules,
    control.network_load_balancer_with_missing_backend,
    control.network_load_balancer_with_nonexistent_backend,
    control.network_private_endpoint_unused,
    control.network_public_ip_unattached,
    control.virtual_network_gateway_unused
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

control "network_application_gateway_with_autoscaling_disabled" {
  title       = "Network Application Gateway with Autoscaling Disabled"
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
    class = "managed"
  })
}

control "network_load_balancer_with_missing_backend" {
  title       = "Network Load Balancer with Missing Backend"
  description = "Load balancer rules without associated backend pools are ineffective and waste resources. These rules should be removed to optimize costs."
  severity    = "low"

  sql = <<-EOT
    select
      r.id as resource,
      case
        when r.backend_address_pool_id is null then 'alarm'
        else 'ok'
      end as status,
      case
        when r.backend_address_pool_id is null then r.name || ' in load balancer ' || r.load_balancer_name || ' has no backend pool configured.'
        else r.name || ' has backend pool configured.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "r.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_lb_rule as r,
      azure_subscription as sub
    where
      sub.subscription_id = r.subscription_id;
  EOT

  tags = merge(local.network_common_tags, {
    class = "unused"
  })
}

control "network_load_balancer_with_nonexistent_backend" {
  title       = "Network Load Balancer with Non-existent Backend"
  description = "Load balancer rules pointing to non-existent backend pools waste resources and should be corrected or removed to optimize costs."
  severity    = "low"

  sql = <<-EOT
    with valid_backend_pools as (
      select distinct id from azure_lb_backend_address_pool
    )
    select
      r.id as resource,
      case
        when r.backend_address_pool_id is not null and not exists (
          select 1 from valid_backend_pools 
          where id = r.backend_address_pool_id
        ) then 'alarm'
        else 'ok'
      end as status,
      case
        when r.backend_address_pool_id is not null and not exists (
          select 1 from valid_backend_pools 
          where id = r.backend_address_pool_id
        ) then r.name || ' in load balancer ' || r.load_balancer_name || ' references non-existent backend pool.'
        else r.name || ' references valid backend pool.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "r.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_lb_rule as r,
      azure_subscription as sub
    where
      sub.subscription_id = r.subscription_id;
  EOT

  tags = merge(local.network_common_tags, {
    class = "unused"
  })
}

control "network_load_balancer_with_duplicate_rules" {
  title       = "Network Load Balancer with Duplicate Rules"
  description = "Duplicate load balancer rules using the same frontend IP and port waste resources and can cause conflicts. These should be consolidated to optimize costs."
  severity    = "low"

  sql = <<-EOT
    with duplicate_rules as (
      select 
        frontend_ip_configuration_id,
        frontend_port,
        protocol,
        count(*) as rule_count
      from 
        azure_lb_rule
      group by 
        frontend_ip_configuration_id,
        frontend_port,
        protocol
      having 
        count(*) > 1
    )
    select
      r.id as resource,
      case
        when dr.rule_count is not null then 'alarm'
        else 'ok'
      end as status,
      case
        when dr.rule_count is not null then r.name || ' in load balancer ' || r.load_balancer_name || 
          ' has duplicate frontend configuration (Port: ' || r.frontend_port || ', Protocol: ' || r.protocol || ').'
        else r.name || ' has unique frontend configuration.'
      end as reason
      ${local.tag_dimensions_sql}
      ${replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "r.")}
      ${replace(local.common_dimensions_subscription_sql, "__QUALIFIER__", "sub.")}
    from
      azure_lb_rule as r
      left join duplicate_rules as dr on
        r.frontend_ip_configuration_id = dr.frontend_ip_configuration_id
        and r.frontend_port = dr.frontend_port
        and r.protocol = dr.protocol,
      azure_subscription as sub
    where
      sub.subscription_id = r.subscription_id;
  EOT

  tags = merge(local.network_common_tags, {
    class = "unused"
  })
}