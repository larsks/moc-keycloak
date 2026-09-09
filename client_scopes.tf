resource "keycloak_openid_client_scope" "groups" {
  consent_screen_text                 = null
  description                         = "A client scope for exposing a group claim"
  extra_config                        = {}
  gui_order                           = null
  include_in_openid_provider_metadata = true
  include_in_token_scope              = true
  name                                = "groups"
  realm_id                            = keycloak_realm.moc.id
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id                   = keycloak_realm.moc.id
  client_scope_id            = keycloak_openid_client_scope.groups.id
  name                       = "groups"
  claim_name                 = "groups"
  full_path                  = false
  add_to_token_introspection = true
}

resource "keycloak_openid_client_scope" "openid" {
  consent_screen_text                 = null
  description                         = "A client scope for the openid client"
  extra_config                        = {}
  gui_order                           = null
  include_in_openid_provider_metadata = false
  include_in_token_scope              = true
  name                                = "openid"
  realm_id                            = keycloak_realm.moc.id
}

resource "keycloak_openid_sub_protocol_mapper" "sub" {
  realm_id        = keycloak_realm.moc.id
  client_scope_id = keycloak_openid_client_scope.openid.id

  name                = "sub"
  add_to_access_token = true
}
