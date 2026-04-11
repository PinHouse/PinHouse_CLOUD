# ========================================
# Artifact Registry 모듈
# ========================================
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id       = var.project_id
  default_location = var.artifact_registry_location
  common_tags      = var.common_tags

  repositories            = var.artifact_registry_repositories
  repository_iam_bindings = var.artifact_registry_repository_iam_bindings
  repository_iam_members  = var.artifact_registry_repository_iam_members
}
