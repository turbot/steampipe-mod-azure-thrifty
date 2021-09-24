---
repository: "https://github.com/turbot/steampipe-mod-azure-thrifty"
---

# Azure Thrifty Mod

Be Thrifty on Azure! This mod checks for unused resources and opportunities to optimize your spend on Azure.

## References

[Azure](https://azure.microsoft.com) provides on-demand cloud computing platforms and APIs to authenticated customers on a metered pay-as-you-go basis.

[Steampipe](https://steampipe.io) is an open source CLI to instantly query cloud APIs using SQL.

[Steampipe Mods](https://steampipe.io/docs/reference/mod-resources#mod) are collections of `named queries`, and codified `controls` that can be used to test current configuration of your cloud resources against a desired configuration.


## Documentation

- **[Benchmarks and controls →](https://hub.steampipe.io/mods/turbot/azure_thrifty/controls)**
- **[Named queries →](https://hub.steampipe.io/mods/turbot/azure_thrifty/queries)**

## Get started

Install the Azure plugin with [Steampipe](https://steampipe.io):
```shell
steampipe plugin install azure
```

Clone:
```sh
git clone https://github.com/turbot/steampipe-mod-azure-thrifty.git
cd steampipe-mod-azure-thrifty
```

Run all benchmarks:
```shell
steampipe check all
```

Run a specific control:
```shell
steampipe check control.compute_disk_unattached
```

### Credentials

This mod uses the credentials configured in the [Steampipe Azure plugin](https://hub.steampipe.io/plugins/turbot/azure).

### Configuration

No extra configuration is required.

## Get involved

* Contribute: [Help wanted issues](https://github.com/turbot/steampipe-mod-azure-thrifty/labels/help%20wanted)
* Community: [Slack channel](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g)
