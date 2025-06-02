## Thrifty Network Benchmark

Thrifty developers ensure that unused IP addresses, virtual network gateways, and private endpoints are removed unless there is a business need to retain them. They also optimize Application Gateway and Load Balancer configurations for cost efficiency.

### Network Public IP Unattached

Unattached public IP addresses continue to incur costs even when they're not associated with any resources. These should be identified and removed to optimize costs. Azure charges for public IP addresses when they are allocated, regardless of whether they are associated with a running resource.

### Virtual Network Gateway Unused

Virtual network gateways that have no active connections should be reviewed and potentially removed. These gateways are billed on an hourly basis regardless of their usage state, making them a significant cost consideration. If a gateway has been idle for an extended period, it may indicate an opportunity for cost optimization by either reconfiguring or removing the resource.

### Network Private Endpoint Unused

Private endpoints that have no service connections should be reviewed and removed if not needed, as they incur unnecessary costs. Each private endpoint is billed based on the hours it is provisioned, regardless of its usage. Removing unused private endpoints helps optimize costs.

### Network Application Gateway with Autoscaling Disabled

Application Gateways should have autoscaling enabled when supported by their SKU tier. The Standard_v2 and WAF_v2 tiers support autoscaling, which can help reduce costs by automatically adjusting capacity based on traffic patterns. For gateways with fixed capacity, having more than 2 instances without autoscaling may indicate an opportunity for cost optimization. Consider enabling autoscaling or reviewing the fixed capacity configuration to ensure it aligns with actual usage patterns.

### Network Load Balancer with Missing Backend

Load balancer rules that have no backend pool configured are ineffective and waste resources. These rules should be identified and removed as they cannot serve any traffic but still contribute to the complexity and management overhead of your load balancer configuration. Regular auditing and removal of such rules helps maintain a clean and cost-effective load balancer setup.

### Network Load Balancer with Invalid Backend

Load balancer rules that point to non-existent backend pools waste resources and should be corrected or removed. These rules can occur when backend pools are deleted but their associated rules remain. Such misconfigured rules can cause confusion, complicate troubleshooting, and waste resources. Identifying and fixing these rules ensures your load balancer configuration remains efficient and cost-effective.

### Network Load Balancer with Duplicate Rules

Load balancers with duplicate rules (same frontend IP and port) waste resources and can cause conflicts. These duplicate configurations often occur during service migrations or updates and should be consolidated. Having multiple rules with the same frontend configuration increases management complexity and can lead to unexpected behavior. Regular auditing and consolidation of duplicate rules helps maintain an efficient and cost-effective load balancer configuration.
