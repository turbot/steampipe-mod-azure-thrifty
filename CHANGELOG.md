## v1.1.0 [2025-06-04]

_What's new?_

- New controls added: ([#52](https://github.com/turbot/steampipe-mod-azure-thrifty/pull/52))
  - `network_application_gateway_with_autoscaling_disabled`
  - `network_load_balancer_with_duplicate_rules`
  - `network_load_balancer_with_missing_backend`
  - `network_load_balancer_with_nonexistent_backend`

## v1.0.1 [2024-10-24]

_Bug fixes_

- Renamed `steampipe.spvars.example` files to `powerpipe.ppvars.example` and updated documentation. ([#50](https://github.com/turbot/steampipe-mod-azure-thrifty/pull/50))

## v1.0.0 [2024-10-22]

This mod now requires [Powerpipe](https://powerpipe.io). [Steampipe](https://steampipe.io) users should check the [migration guide](https://powerpipe.io/blog/migrating-from-steampipe).

## v0.10 [2024-04-06]

_Powerpipe_

[Powerpipe](https://powerpipe.io) is now the preferred way to run this mod!  [Migrating from Steampipe →](https://powerpipe.io/blog/migrating-from-steampipe)

All v0.x versions of this mod will work in both Steampipe and Powerpipe, but v1.0.0 onwards will be in Powerpipe format only.

_Enhancements_

- Focus documentation on Powerpipe commands.
- Show how to combine Powerpipe mods with Steampipe plugins.

## v0.9 [2023-03-03]

_What's new?_

- Added `tags` as dimensions to group and filter findings. (see [var.tag_dimensions](https://hub.steampipe.io/mods/turbot/azure_thrifty/variables)) ([#37](https://github.com/turbot/steampipe-mod-azure-thrifty/pull/37))
- Added `connection_name`, `region` and `subscription_id` in the common dimensions to group and filter findings. (see [var.common_dimensions](https://hub.steampipe.io/mods/turbot/azure_thrifty/variables)) ([#37](https://github.com/turbot/steampipe-mod-azure-thrifty/pull/37))

_Bug fixes_

- Fixed the inline query of `compute_virtual_machine_long_running` control to remove duplicate results. ([#35](https://github.com/turbot/steampipe-mod-azure-thrifty/pull/35)) (Thanks [@JoshRosen](https://github.com/JoshRosen) for the contribution!)

## v0.8 [2022-05-09]

_Enhancements_

- Updated docs/index.md and README with new dashboard screenshots and latest format. ([#31](https://github.com/turbot/steampipe-mod-azure-thrifty/pull/31))

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
