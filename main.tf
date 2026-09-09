
locals {
  realm_id = "moc"
  openshift_oidc_clusters = {
    oac_prod_workload0 = {
      cluster_name           = "oac-prod-workload0"
      openshift_redirect_uri = "https://oauth-oac-prod-workload0.hcp.oac.massopen.cloud:443/oauth2callback/mocsso"
      client_secret_name     = "cluster/oac-prod-infra/hostedcluster/oac-prod-workload0/keycloak-oidc"
      keycloak_client_uuid   = "oac-prod-workload0"
    }
    oac_dev_workload0 = {
      cluster_name           = "oac-dev-workload0"
      openshift_redirect_uri = "https://oauth-oac-dev-workload0.hcp.oac.int.massopen.cloud:443/oauth2callback/mocsso"
      client_secret_name     = "cluster/oac-dev-infra/hostedcluster/oac-dev-workload0/keycloak-oidc"
      keycloak_client_uuid   = "oac-dev-workload0"
    }
  }
}

module "openshift_oidc" {
  for_each = local.openshift_oidc_clusters

  source                 = "./modules/openshift-oidc"
  cluster_name           = each.value.cluster_name
  openshift_redirect_uri = each.value.openshift_redirect_uri
  client_secret_name     = each.value.client_secret_name
  realm_id               = keycloak_realm.moc.id
  use_secrets_manager    = var.use_secrets_manager
  additional_scope_names = [keycloak_openid_client_scope.groups.name, keycloak_openid_client_scope.openid.name]
}
