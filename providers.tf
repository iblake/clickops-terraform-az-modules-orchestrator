# Azure Provider Configuration

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# Data sources for Azure regions and current subscription
data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

locals {
  # Get current subscription details
  subscription_id = data.azurerm_subscription.current.subscription_id
  tenant_id      = data.azurerm_client_config.current.tenant_id

  # Default location if not specified
  default_location = "eastus"
}
