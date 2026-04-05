# ========================================
# Secret Manager 모듈
# ========================================
module "secret_manager" {
  source = "../../modules/secret-manager"

  project_id  = var.project_id
  common_tags = var.common_tags

  secret_ids          = var.secret_manager_secret_ids
  secret_iam_bindings = var.secret_manager_secret_iam_bindings
  secret_iam_members  = var.secret_manager_secret_iam_members
}
