## Managed By : Thoughtfocus
## Copyright @ Thoughtfocs. All Right Reserved.

#Module      : labels
#Description : Terraform module to create consistent naming for multiple names.
module "labels" {
  source  = "git::https://dev.azure.com/gcloudvenki231/IaC/_git/terraform//modules/terraform-azure-labels"

  name          = var.name
  environment   = var.environment
  managedby     = var.managedby
  business_unit = var.business_unit
  label_order   = var.label_order
  repository    = var.repository
}

#Module      : RESOURCE GROUP
#Description : Terraform resource for resource group.
resource "azurerm_resource_group" "default" {
  count    = var.enabled ? 1 : 0
  name     = format("rg-%s", module.labels.id)
  location = var.location
  tags     = module.labels.tags

  timeouts {
    create = var.create
    read   = var.read
    update = var.update
    delete = var.delete
  }
}

resource "azurerm_management_lock" "resource-group-level" {
  count      = var.enabled && var.resource_lock_enabled ? 1 : 0
  name       = format("%s-rg-lock", var.lock_level)
  scope      = azurerm_resource_group.default.*.id[0]
  lock_level = var.lock_level
  notes      = "This Resource Group is locked by terrafrom. Please reach out to Devops team."
}