locals {
  thrifty_common_tags = {
    plugin      = "azure"
  }
  required_azure_tags = [
    "azure:createdBy"
  ]
}