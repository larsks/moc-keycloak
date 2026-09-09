variable "cluster_name" {
  type        = string
  description = "The name of the OpenShift cluster"
}

variable "openshift_redirect_uri" {
  type        = string
  description = "The OAuth2 callback URL of the OpenShift Cluster for the Keycloak identity provider"
}

variable "client_secret_name" {
  type        = string
  description = "The Keycloak client_id and client_secret for the OpenShift cluster"
}

variable "use_secrets_manager" {
  type        = bool
  default     = true
  description = "Store secrets to AWS Secrets Manager when true"
}

variable "realm_id" {
  type        = string
  description = "Realm that owns this OIDC resources"
}

variable "additional_scope_names" {
  type        = list(string)
  description = "List of additional scopes to associate with the client"
  default     = []
}
