# Backend Configuration
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfmgmt-dev"
    storage_account_name = "tfmgmtstatess"
    container_name       = "terraformstates"
    key                  = "terraform-devv.tfstate"
  }
}

# Azure Resource Group Module
module "resource_group" {
  source = "git::https://dev.azure.com/gcloudvenki231/IaC/_git/terraform//modules/terraform-azure-rg"

  name        = "app-100"
  environment = "test"
  label_order = ["environment", "name", ]
  location    = "East US"
}

# Azure Virtual Machine Module
module "vnet" {
  source = "git::https://dev.azure.com/gcloudvenki231/IaC/_git/terraform//modules/terraform-azure-vnet"

  name                = "app"
  environment         = "test"
  label_order         = ["name", "environment"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.30.0.0/16"]
}

# Azure Subnet Module
module "subnet" {
  source = "git::https://dev.azure.com/gcloudvenki231/IaC/_git/terraform//modules/terraform-azure-subnet"

  name                 = "app"
  environment          = "test"
  label_order          = ["name", "environment"]
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name

  #subnet
  subnet_names    = ["subnet1", "subnet2"]
  subnet_prefixes = ["10.30.1.0/24", "10.30.2.0/24"]

  # route_table
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

module "aks" {
  source      = "git::https://dev.azure.com/gcloudvenki231/IaC/_git/terraform//modules/terraform-azure-aks"
  name        = "app"
  environment = "test"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location

  kubernetes_version      = "1.25.5"
  private_cluster_enabled = false
  default_node_pool = {
    name                  = "agentpool1"
    max_pods              = 200
    os_disk_size_gb       = 64
    vm_size               = "Standard_B4ms"
    count                 = 1
    enable_node_public_ip = false
  }


  ##### if requred more than one node group.
  nodes_pools = [
    {
      name                  = "nodegroup2"
      max_pods              = 200
      os_disk_size_gb       = 64
      vm_size               = "Standard_B4ms"
      count                 = 1
      enable_node_public_ip = false
      mode                  = "User"
    },
  ]

  #networking
  vnet_id         = join("", module.vnet.vnet_id)
  nodes_subnet_id = module.subnet.default_subnet_id[0]

  # acr_id       = "****" #pass this value if you  want aks to pull image from acr else remove it
  #  key_vault_id = module.vault.id #pass this value of variable 'cmk_enabled = true' if you want to enable Encryption with a Customer-managed key else remove it.

  #### enable diagnostic setting.
  # microsoft_defender_enabled = true
  # diagnostic_setting_enable  = true
  # log_analytics_workspace_id = module.log-analytics.workspace_id # when diagnostic_setting_enable = true && oms_agent_enabled = true
}