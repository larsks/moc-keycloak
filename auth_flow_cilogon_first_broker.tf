# Keycloak represents a flow as a *tree*: a flow contains executions and
# subflows, and subflows contain their own executions/subflows. Ordering within
# a given parent is controlled by `priority` (lowest first); nesting is
# controlled by `parent_flow_alias`, which points at the immediate parent's
# alias.

resource "keycloak_authentication_flow" "cilogon_first_broker_login" {
  realm_id    = keycloak_realm.moc.id
  alias       = "CILogon First Broker Login"
  description = "Actions taken after first broker login with identity provider account, which is not yet linked to any Keycloak account"
  provider_id = "basic-flow"
}

# -- Top level ----------------------------------------------------------------

resource "keycloak_authentication_execution" "review_profile" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_flow.cilogon_first_broker_login.alias
  authenticator     = "idp-review-profile"
  requirement       = "DISABLED"
  priority          = 10
}

resource "keycloak_authentication_subflow" "user_creation_or_linking" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_flow.cilogon_first_broker_login.alias
  alias             = "CILogon First Broker Login User creation or linking"
  description       = "Flow for the existing/non-existing user alternatives"
  provider_id       = "basic-flow"
  requirement       = "REQUIRED"
  priority          = 20
}

resource "keycloak_authentication_subflow" "conditional_organization" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_flow.cilogon_first_broker_login.alias
  alias             = "CILogon First Broker Login First Broker Login - Conditional Organization"
  description       = "Flow to determine if the authenticator that adds organization members is to be used"
  provider_id       = "basic-flow"
  requirement       = "CONDITIONAL"
  priority          = 60

  # Keycloak has a race condition when multiple resources write concurrently to
  # the same parent flow's execution list: the GET that follows a POST can NPE
  # because the inner-flow reference isn't yet visible. Serialise creation of
  # top-level siblings within cilogon_first_broker_login to avoid this.
  depends_on = [
    keycloak_authentication_execution.review_profile,
    keycloak_authentication_subflow.user_creation_or_linking,
  ]
}

# -- User creation or linking -------------------------------------------------

resource "keycloak_authentication_execution" "create_user_if_unique" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.user_creation_or_linking.alias
  authenticator     = "idp-create-user-if-unique"
  requirement       = "ALTERNATIVE"
  priority          = 10
}

resource "keycloak_authentication_subflow" "handle_existing_account" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.user_creation_or_linking.alias
  alias             = "CILogon First Broker Login Handle Existing Account"
  description       = "Handle what to do if there is existing account with same email/username like authenticated identity provider"
  provider_id       = "basic-flow"
  requirement       = "ALTERNATIVE"
  priority          = 20
}

# -- Handle Existing Account --------------------------------------------------

resource "keycloak_authentication_execution" "confirm_link" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.handle_existing_account.alias
  authenticator     = "idp-confirm-link"
  requirement       = "DISABLED"
  priority          = 10
}

resource "keycloak_authentication_subflow" "account_verification_options" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.handle_existing_account.alias
  alias             = "CILogon First Broker Login Account verification options"
  description       = "Method with which to verify the existing account"
  provider_id       = "basic-flow"
  requirement       = "REQUIRED"
  priority          = 20
}

# -- Account verification options ---------------------------------------------

resource "keycloak_authentication_execution" "email_verification" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.account_verification_options.alias
  authenticator     = "idp-email-verification"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_subflow" "verify_existing_account_by_reauthentication" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.account_verification_options.alias
  alias             = "CILogon First Broker Login Verify Existing Account by Re-authentication"
  description       = "Reauthentication of existing account"
  provider_id       = "basic-flow"
  requirement       = "DISABLED"
  priority          = 20
}

# -- Verify Existing Account by Re-authentication -----------------------------

resource "keycloak_authentication_execution" "username_password_form" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.verify_existing_account_by_reauthentication.alias
  authenticator     = "idp-username-password-form"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_subflow" "conditional_2fa" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.verify_existing_account_by_reauthentication.alias
  alias             = "CILogon First Broker Login First broker login - Conditional 2FA"
  description       = "Flow to determine if any 2FA is required for the authentication"
  provider_id       = "basic-flow"
  requirement       = "CONDITIONAL"
  priority          = 20
}

# -- First broker login - Conditional 2FA -------------------------------------

resource "keycloak_authentication_execution" "conditional_2fa_user_configured" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.conditional_2fa.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_execution" "conditional_2fa_credential" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.conditional_2fa.alias
  authenticator     = "conditional-credential"
  requirement       = "REQUIRED"
  priority          = 20
}

resource "keycloak_authentication_execution" "conditional_2fa_otp" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.conditional_2fa.alias
  authenticator     = "auth-otp-form"
  requirement       = "DISABLED"
  priority          = 30
}

resource "keycloak_authentication_execution" "conditional_2fa_webauthn" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.conditional_2fa.alias
  authenticator     = "webauthn-authenticator"
  requirement       = "DISABLED"
  priority          = 40
}

resource "keycloak_authentication_execution" "conditional_2fa_recovery_code" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.conditional_2fa.alias
  authenticator     = "auth-recovery-authn-code-form"
  requirement       = "DISABLED"
  priority          = 50
}

# -- First Broker Login - Conditional Organization ----------------------------

resource "keycloak_authentication_execution" "conditional_org_user_configured" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.conditional_organization.alias
  authenticator     = "conditional-user-configured"
  requirement       = "REQUIRED"
  priority          = 10
}

resource "keycloak_authentication_execution" "add_organization_member" {
  realm_id          = keycloak_realm.moc.id
  parent_flow_alias = keycloak_authentication_subflow.conditional_organization.alias
  authenticator     = "idp-add-organization-member"
  requirement       = "REQUIRED"
  priority          = 20
}
