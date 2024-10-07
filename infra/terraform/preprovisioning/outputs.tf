output "application_insights_instrumentation_key" {
  value = azurerm_application_insights.main.instrumentation_key
}

output "application_insights_app_id" {
  value = azurerm_application_insights.main.app_id
}
