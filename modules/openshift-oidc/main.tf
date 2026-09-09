terraform {
  required_version = ">= 1.6.0"

  required_providers {
    keycloak = {
      source  = "registry.terraform.io/keycloak/keycloak"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# OpenShift OIDC – IAM OIDC provider
# -----------------------------------------------------------------------------

resource "keycloak_openid_client" "this" {
  access_token_lifespan                          = ""
  access_type                                    = "CONFIDENTIAL"
  admin_url                                      = ""
  allow_refresh_token_in_standard_token_exchange = ""
  always_display_in_console                      = false
  backchannel_logout_revoke_offline_sessions     = false
  backchannel_logout_session_required            = true
  backchannel_logout_url                         = ""
  base_url                                       = ""
  client_authenticator_type                      = "client-secret"
  client_id                                      = var.cluster_name
  client_offline_session_idle_timeout            = ""
  client_offline_session_max_lifespan            = ""
  client_secret                                  = null # sensitive
  client_secret_regenerate_when_changed          = null
  client_secret_wo                               = null # sensitive
  client_secret_wo_version                       = null
  client_session_idle_timeout                    = ""
  client_session_max_lifespan                    = ""
  consent_required                               = false
  consent_screen_text                            = ""
  description                                    = ""
  direct_access_grants_enabled                   = true
  display_on_consent_screen                      = false
  enabled                                        = true
  exclude_issuer_from_auth_response              = null
  exclude_session_state_from_auth_response       = null
  extra_config                                   = {}
  frontchannel_logout_enabled                    = true
  frontchannel_logout_url                        = ""
  full_scope_allowed                             = true
  implicit_flow_enabled                          = false
  import                                         = false
  login_theme                                    = ""
  name                                           = var.cluster_name
  oauth2_device_authorization_grant_enabled      = false
  oauth2_device_code_lifespan                    = ""
  oauth2_device_polling_interval                 = ""
  oauth2_jwt_authorization_grant_enabled         = false
  oauth2_jwt_authorization_grant_idp             = ""
  pkce_code_challenge_method                     = ""
  realm_id                                       = var.realm_id
  require_dpop_bound_tokens                      = false
  root_url                                       = ""
  service_accounts_enabled                       = true
  standard_flow_enabled                          = true
  standard_token_exchange_enabled                = false
  use_refresh_tokens                             = false
  use_refresh_tokens_client_credentials          = false
  valid_post_logout_redirect_uris                = []
  valid_redirect_uris                            = ["${var.openshift_redirect_uri}"]
  web_origins                                    = []
  authorization {
    allow_remote_resource_management = true
    decision_strategy                = "AFFIRMATIVE"
    keep_defaults                    = false
    policy_enforcement_mode          = "ENFORCING"
  }
}

# -----------------------------------------------------------------------------
# Store Keycloak client secrets in Secrets Manager
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "this" {
  count = var.use_secrets_manager ? 1 : 0

  name                    = var.client_secret_name
  description             = "The Keycloak client_id and client_secret for the ${var.cluster_name} OpenShift cluster"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "this" {
  count = var.use_secrets_manager ? 1 : 0

  secret_id = aws_secretsmanager_secret.this[0].id
  secret_string = jsonencode({
    client_id     = keycloak_openid_client.this.client_id
    client_secret = keycloak_openid_client.this.client_secret
  })
}

resource "keycloak_openid_client_default_scopes" "this" {
  realm_id  = var.realm_id
  client_id = keycloak_openid_client.this.id

  default_scopes = concat([
    "service_account",
    "profile",
  ], var.additional_scope_names)
}

resource "keycloak_openid_client_optional_scopes" "this" {
  realm_id  = var.realm_id
  client_id = keycloak_openid_client.this.id

  optional_scopes = []
}
