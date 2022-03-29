# Azure Thrifty

An Azure cost savings and waste checking tool.

## Quick start

1) Download and install Steampipe (https://steampipe.io/downloads). Or use Brew:

```shell
brew tap turbot/tap
brew install steampipe

steampipe -v
steampipe version 0.8.2
```

Install the Azure plugin

```shell
steampipe plugin install azure
```

Clone this repo and move into the directory:

```sh
git clone https://github.com/turbot/steampipe-mod-azure-thrifty.git
cd steampipe-mod-azure-thrifty
```

Run all benchmarks:

```shell
steampipe check all
```

![image](https://raw.githubusercontent.com/turbot/steampipe-mod-azure-thrifty/main/docs/azure-thrifty-console-graphic.png)

Your can also run a specific controls:

```shell
steampipe check control.compute_disk_unattached
```

### Credentials

This mod uses the credentials configured in the [Steampipe Azure plugin](https://hub.steampipe.io/plugins/turbot/azure).

### Configuration

Several benchmarks have [input variables](https://steampipe.io/docs/using-steampipe/mod-variables) that can be configured to better match your environment and requirements. Each variable has a default defined in its source file, e.g., `controls/sql.sp`, but these can be overwritten in several ways:

- Copy and rename the `steampipe.spvars.example` file to `steampipe.spvars`, and then modify the variable values inside that file
- Pass in a value on the command line:

  ```shell
  steampipe check benchmark.compute --var=compute_disk_max_size_gb=100
  ```

- Set an environment variable:

  ```shell
  compute_disk_max_size_gb=100 steampipe check control.compute_disk_large
  ```

  - Note: When using environment variables, if the variable is defined in `steampipe.spvars` or passed in through the command line, either of those will take precedence over the environment variable value. For more information on variable definition precedence, please see the link below.

These are only some of the ways you can set variables. For a full list, please see [Passing Input Variables](https://steampipe.io/docs/using-steampipe/mod-variables#passing-input-variables).

## Current Thrifty Checks

- Long running **Compute Virtual Machines**
- Unused and oversized **Compute Disks** and **Snapshots**
- Unattached **Network Public IPs**
- Long running **SQL Databases**
- [#TODO List](https://github.com/turbot/steampipe-mod-azure-thrifty/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

**Use introspection to view the available controls:**:

```shell
steampipe query "select resource_name from steampipe_control;"
```

## Contributing

Have an idea for a thrifty check but aren't sure how to get started?

- **[Join our Slack community →](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g)**
- **[Mod developer guide →](https://steampipe.io/docs/using-steampipe/writing-controls)**

**Prerequisites**:

- [Steampipe installed](https://steampipe.io/downloads)
- Steampipe Azure plugin installed (see above)

**Fork**:
Click on the GitHub Fork Widget. (Don't forget to :star: the repo!)

**Clone**:

1. Change the current working directory to the location where you want to put the cloned directory on your local filesystem.
2. Type the clone command below inserting your GitHub username instead of `YOUR-USERNAME`:

```sh
git clone git@github.com:YOUR-USERNAME/steampipe-mod-azure-thrifty
cd steampipe-mod-azure-thrifty
```

Thanks for getting involved! We would love to have you [join our Slack community](https://join.slack.com/t/steampipe/shared_invite/zt-oij778tv-lYyRTWOTMQYBVAbtPSWs3g) and hang out with other Mod developers.

Please see the [contribution guidelines](https://github.com/turbot/steampipe/blob/main/CONTRIBUTING.md) and our [code of conduct](https://github.com/turbot/steampipe/blob/main/CODE_OF_CONDUCT.md). All contributions are subject to the [Apache 2.0 open source license](https://github.com/turbot/steampipe-mod-azure-thrifty/blob/main/LICENSE).

`help wanted` issues:

- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [Azure Thrifty Mod](https://github.com/turbot/steampipe-mod-azure-thrifty/labels/help%20wanted)
