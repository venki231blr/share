

module "labels" {
  source      = "git::https://dev.azure.com/gcloudvenki231/IaC/_git/terraform//modules/terraform-azure-labels"
  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
}

resource "azurerm_log_analytics_workspace" "main" {
  count                      = var.enabled && var.create_log_analytics_workspace == true ? 1 : 0
  name                       = format("%s-logs", module.labels.id)
  location                   = var.log_analytics_workspace_location
  resource_group_name        = var.resource_group_name
  sku                        = var.log_analytics_workspace_sku
  retention_in_days          = var.retention_in_days
  daily_quota_gb             = var.daily_quota_gb
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled
  tags                       = module.labels.tags
}
resource "azurerm_monitor_diagnostic_setting" "example" {
  count                          = var.enabled && var.diagnostic_setting_enable ? 1 : 0
  name                           = format("%s-log-analytics-diagnostic-log", module.labels.id)
  target_resource_id             = join("", azurerm_log_analytics_workspace.main.*.id)
  storage_account_id             = var.storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type
  metric {
    category = "AllMetrics"
    enabled  = var.Metric_enable
    retention_policy {
      enabled = var.retention_policy_enabled
      days    = var.days
    }
  }
  log {
    category       = var.category
    category_group = "AllLogs"
    retention_policy {
      enabled = var.retention_policy_enabled
      days    = var.days
    }
    enabled = var.log_enabled
  }

  log {
    category       = var.category
    category_group = "Audit"
    retention_policy {
      enabled = var.retention_policy_enabled
      days    = var.days
    }
    enabled = var.log_enabled
  }
  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}