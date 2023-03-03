// Benchmarks and controls for specific services should override the "service" tag
locals {
  azure_thrifty_common_tags = {
    category = "Cost"
    plugin   = "azure"
    service  = "Azure"
  }
}

variable "common_dimensions" {
  type        = list(string)
  description = "A list of common dimensions to add to each control."
  # Define which common dimensions should be added to each control.
  # - connection_name (_ctx ->> 'connection_name')
  # - region
  # - resource_group
  # - subscription
  # - subscription_id
  default     = [ "resource_group", "subscription" ]
}

variable "tag_dimensions" {
  type        = list(string)
  description = "A list of tags to add as dimensions to each control."
  default     = []
}

locals {

  common_dimensions_qualifier_sql = <<-EOQ
  %{~ if contains(var.common_dimensions, "connection_name") }, __QUALIFIER___ctx ->> 'connection_name' as connection_name%{ endif ~}
  %{~ if contains(var.common_dimensions, "region") }, __QUALIFIER__region%{ endif ~}
  %{~ if contains(var.common_dimensions, "resource_group") }, __QUALIFIER__resource_group%{ endif ~}
  %{~ if contains(var.common_dimensions, "subscription_id") }, __QUALIFIER__subscription_id%{ endif ~}
  EOQ

  common_dimensions_qualifier_subscription_sql = <<-EOQ
  %{~ if contains(var.common_dimensions, "subscription") }, __QUALIFIER__display_name as subscription%{ endif ~}
  EOQ

  tag_dimensions_sql = <<-EOQ
  %{~ for dim in var.tag_dimensions }, tags ->> '${dim}' as "${replace(dim, "\"", "\"\"")}"%{ endfor ~}
  EOQ

}

locals {

  common_dimensions_sql = replace(local.common_dimensions_qualifier_sql, "__QUALIFIER__", "")
  common_dimensions_subscription_sql = replace(local.common_dimensions_qualifier_subscription_sql, "__QUALIFIER__", "")
}

mod "azure_thrifty" {
  # hub metadata
  title         = "Azure Thrifty"
  description   = "Are you a Thrifty Azure developer? This Steampipe mod checks your Azure subscription(s) to check for unused and under utilized resources."
  color         = "#0089D6"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/azure-thrifty.svg"
  categories    = ["azure", "cost", "thrifty", "public cloud"]

  opengraph {
    title       = "Thrifty mod for Azure"
    description = "Are you a Thrifty Azure dev? This Steampipe mod checks your Azure subscription(s) for unused and under-utilized resources."
    image       = "/images/mods/turbot/azure-thrifty-social-graphic.png"
  }
}
