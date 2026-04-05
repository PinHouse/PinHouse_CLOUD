# ========================================
# Artifact Registry Private Google Access 모듈
# ========================================
module "artifact_registry_private_access" {
  source = "../../modules/private-google-access"

  project_id               = var.project_id
  network_self_link        = module.vpc.vpc_self_link
  name_prefix              = "${var.environment}-artifact-registry"
  google_api_domain_option = var.google_api_domain_option
}
