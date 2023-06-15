provider "azuread" {
}

locals {
  application_name             = "${var.unique_project_name}-rabbitmq-app"
  # list of roles to create in application - see https://www.rabbitmq.com/oauth2.html#scope-and-tags
  rabbitmq_roles = {
    management = "tag:management"
    administrator = "tag:administrator"
    read_all = "read:*/*/*"
    write_all = "write:*/*/*"
    configure_all = "configure:*/*/*"
  }
  rabbitmq_app_identifier = "api://${local.application_name}"
}

resource "random_uuid" "rabbit_app_role" {
  for_each = local.rabbitmq_roles
}

resource "random_uuid" "rabbit_app_scope" {}

resource "azuread_application" "rabbit_oauth2_api" {

  display_name = "${local.application_name} OAuth2 API tokens app for RabbitMQ"

  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2

    oauth2_permission_scope {
      id                         = random_uuid.rabbit_app_scope.id
      admin_consent_description  = "Dummy text for dummy application"
      admin_consent_display_name = "Dummy text for dummy application"
      enabled                    = true
      type                       = "User"
      user_consent_description   = "Dummy text for dummy application"
      user_consent_display_name  = "Dummy text for dummy application"
      value                      = "access"
    }
  }

  identifier_uris = [local.rabbitmq_app_identifier]

  dynamic "app_role" {
    for_each = local.rabbitmq_roles
    content {
      id                   = random_uuid.rabbit_app_role[app_role.key].id
      allowed_member_types = ["User", "Application"]
      value                = "${local.rabbitmq_app_identifier}.${app_role.value}" # prefixed for RabbitMQ
      display_name         = app_role.key
      description          = "${app_role.key} role for RabbitMQ instance"
      enabled              = true
    }
  }
}

resource "azuread_service_principal" "rabbit_oauth2_api" {
  application_id = azuread_application.rabbit_oauth2_api.application_id
  use_existing = true
}

locals {
  # assign each role to each identity requested
  rabbit_oauth2_api_roles = flatten([
    for role,_ in local.rabbitmq_roles : [
      for identity in var.rabbitmq_access_identities : {
        role_uuid_key = random_uuid.rabbit_app_role[role].id
        principal_id = identity.principal_id
      }
    ]
  ])
}

resource "azuread_app_role_assignment" "rabbit_oauth2_api_access" {
  count = length(local.rabbit_oauth2_api_roles)

  app_role_id         = local.rabbit_oauth2_api_roles[count.index].role_uuid_key
  principal_object_id = local.rabbit_oauth2_api_roles[count.index].principal_id
  resource_object_id  = azuread_service_principal.rabbit_oauth2_api.object_id
}
