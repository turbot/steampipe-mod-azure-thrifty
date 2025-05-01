## Thrifty Network Benchmark

Thrifty developers ensure that unused IP addresses, virtual network gateways, and private endpoints are removed unless there is a business need to retain them.

### Network Public IP Unattached

Unattached public IP addresses continue to incur costs even when they're not associated with any resources. These should be identified and removed to optimize costs. Azure charges for public IP addresses when they are allocated, regardless of whether they are associated with a running resource.

### Virtual Network Gateway Unused

Virtual network gateways that have no active connections should be reviewed and potentially removed. These gateways are billed on an hourly basis regardless of their usage state, making them a significant cost consideration. If a gateway has been idle for an extended period, it may indicate an opportunity for cost optimization by either reconfiguring or removing the resource.

### Network Private Endpoint Unused

Private endpoints that have no service connections should be reviewed and removed if not needed, as they incur unnecessary costs. Each private endpoint is billed based on the hours it is provisioned, regardless of its usage. Removing unused private endpoints helps optimize costs.
