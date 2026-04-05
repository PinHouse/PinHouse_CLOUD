# ========================================
# 공통 로컬 값
# ========================================
locals {
  normalized_common_tags = {
    for key, value in var.common_tags :
    lower(key) => lower(value)
  }
}

# ========================================
# Secret Manager API 리소스
# ========================================
resource "google_project_service" "secret_manager_api" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# ========================================
# Secret Manager 리소스
# ========================================
resource "google_secret_manager_secret" "secrets" {
  for_each = var.secret_ids

  project   = var.project_id
  secret_id = each.value

  replication {
    auto {}
  }

  labels = local.normalized_common_tags

  depends_on = [google_project_service.secret_manager_api]
}

# ========================================
# Secret IAM 리소스
# ========================================
resource "google_secret_manager_secret_iam_binding" "secret_iam" {
  for_each = var.secret_iam_bindings

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = each.value.role
  members   = each.value.members
}

resource "google_secret_manager_secret_iam_member" "secret_iam_member" {
  for_each = var.secret_iam_members

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = each.value.role
  member    = each.value.member
}
