output "application_id" {
  value = azuread_application.rabbit_oauth2_api.application_id
}

output "application_scope_name" {
  value = local.rabbitmq_app_identifier
}
