mod "azure_thrifty" {
  # Hub metadata
  title         = "Azure Thrifty"
  description   = "Are you a Thrifty Azure developer? This mod checks your Azure subscription(s) to check for unused and under utilized resources using Powerpipe and Steampipe."
  color         = "#0089D6"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/azure-thrifty.svg"
  categories    = ["azure", "cost", "thrifty", "public cloud"]

  opengraph {
    title       = "Powerpipe mod for Azure Thrifty"
    description = "Are you a Thrifty Azure dev? This mod checks your Azure subscription(s) for unused and under-utilized resources using Powerpipe and Steampipe."
    image       = "/images/mods/turbot/azure-thrifty-social-graphic.png"
  }
}
