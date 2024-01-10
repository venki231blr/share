# Terraform version
# terraform {
#   required_version = ">= 1.3.0"
#   #experiments      = [module_variable_optional_attrs]
# }

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.15.0"
    }
  }
}