## v0.7 [2022-05-02]

_Enhancements_

- Added `category`, `service`, and `type` tags to benchmarks and controls. ([#27](https://github.com/turbot/steampipe-mod-azure-thrifty/pull/27))

## v0.6 [2022-03-23]

_What's new?_

- Added default values to all variables (set to the same values in `steampipe.spvars.example`)
- Added `*.spvars` and `*.auto.spvars` files to `.gitignore`
- Renamed `steampipe.spvars` to `steampipe.spvars.example`, so the variable default values will be used initially. To use this example file instead, copy `steampipe.spvars.example` as a new file `steampipe.spvars`, and then modify the variable values in it. For more information on how to set variable values, please see [Input Variable Configuration](https://hub.steampipe.io/mods/turbot/azure_thrifty#configuration).

## v0.5 [2021-11-10]

_Enhancements_

- `docs/index.md` file now includes the console output image

## v0.4 [2021-09-30]

_What's new?_

- Added: Input variables have been added to Compute and SQL controls to allow different thresholds to be passed in. To get started, please see [Azure Thrifty Configuration](https://hub.steampipe.io/mods/turbot/azure_thrifty#configuration). For a list of variables and their default values, please see [steampipe.spvars](https://github.com/turbot/steampipe-mod-azure-thrifty/blob/main/steampipe.spvars).

## v0.3 [2021-09-23]

_Bug fixes_

- Fixed broken links to the Mod developer guide and LICENSE in README.md

## v0.2 [2021-07-23]

_What's new?_

- New controls added:
  - compute_disk_low_usage
  - compute_virtual_machine_low_utilization
  - virtual_network_gateway_unused
  - storage_account_without_lifecycle_policy

## v0.1 [2021-07-02]

_What's new?_

- Added initial Compute, Network, and SQL benchmarks
