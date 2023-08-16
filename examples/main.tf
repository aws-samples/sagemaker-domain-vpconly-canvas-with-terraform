module "sagemaker_domain" {
  source                  = "../"
  domain_name             = var.domain_name
  auth_mode               = var.auth_mode
  app_network_access_type = var.app_network_access_type
  efs_retention_policy    = var.efs_retention_policy
}
