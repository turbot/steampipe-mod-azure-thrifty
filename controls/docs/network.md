## Thrifty Network Benchmark

Thrifty developers ensure that unused IP addresses, virtual network gateways, and private endpoints are removed unless there is a business need to retain them. They also optimize Application Gateway configurations for cost efficiency.

### Network Public IP Unattached

Unattached public IP addresses continue to incur costs even when they're not associated with any resources. These should be identified and removed to optimize costs. Azure charges for public IP addresses when they are allocated, regardless of whether they are associated with a running resource.

### Virtual Network Gateway Unused

Virtual network gateways that have no active connections should be reviewed and potentially removed. These gateways are billed on an hourly basis regardless of their usage state, making them a significant cost consideration. If a gateway has been idle for an extended period, it may indicate an opportunity for cost optimization by either reconfiguring or removing the resource.

### Network Private Endpoint Unused

Private endpoints that have no service connections should be reviewed and removed if not needed, as they incur unnecessary costs. Each private endpoint is billed based on the hours it is provisioned, regardless of its usage. Removing unused private endpoints helps optimize costs.

### Application Gateway Optimization

Application Gateways should be configured for optimal cost efficiency. The Standard_v2 and WAF_v2 tiers support autoscaling, which can help reduce costs by automatically adjusting capacity based on traffic patterns. For gateways with fixed capacity, having more than 2 instances without autoscaling may indicate an opportunity for cost optimization. Consider enabling autoscaling or reviewing the fixed capacity configuration to ensure it aligns with actual usage patterns.

### Load Balancer Rules Optimization

Standard SKU load balancers with more than 5 rules should be reviewed for optimization opportunities. Having too many rules on a single load balancer can lead to increased management complexity and potential performance impacts. Consider consolidating rules where possible or distributing them across multiple load balancers if the rules serve different application components or traffic patterns. This check only applies to Standard SKU load balancers as they are designed for production workloads that require high availability and scalability.
