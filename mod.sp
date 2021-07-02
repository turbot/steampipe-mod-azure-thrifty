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
