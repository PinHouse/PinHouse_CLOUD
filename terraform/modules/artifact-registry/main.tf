# ========================================
# Artifact Registry API 리소스
# ========================================
resource "google_project_service" "artifact_registry_api" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# ========================================
# Artifact Registry 저장소 리소스
# ========================================
resource "google_artifact_registry_repository" "repositories" {
  for_each = var.repositories

  project       = var.project_id
  location      = coalesce(lookup(each.value, "location", null), var.default_location)
  repository_id = each.value.repository_id
  description   = coalesce(lookup(each.value, "description", null), "Terraform로 관리되는 Artifact Registry 저장소")
  format        = upper(each.value.format)

  labels = merge(
    {
      for k, v in var.common_tags : lower(k) => lower(v)
    },
    {
      for k, v in coalesce(lookup(each.value, "common_tags", null), {}) : lower(k) => lower(v)
    }
  )

  # Docker 저장소일 때만 immutable_tags 설정을 적용합니다.
  dynamic "docker_config" {
    for_each = upper(each.value.format) == "DOCKER" && lookup(each.value, "immutable_tags", null) != null ? [1] : []
    content {
      immutable_tags = each.value.immutable_tags
    }
  }

  depends_on = [google_project_service.artifact_registry_api]
}

# ========================================
# 저장소 IAM 리소스
# ========================================
resource "google_artifact_registry_repository_iam_binding" "repository_iam" {
  for_each = var.repository_iam_bindings

  project    = var.project_id
  location   = google_artifact_registry_repository.repositories[each.value.repository_key].location
  repository = google_artifact_registry_repository.repositories[each.value.repository_key].name
  role       = each.value.role
  members    = each.value.members
}

resource "google_artifact_registry_repository_iam_member" "repository_iam_member" {
  for_each = var.repository_iam_members

  project    = var.project_id
  location   = google_artifact_registry_repository.repositories[each.value.repository_key].location
  repository = google_artifact_registry_repository.repositories[each.value.repository_key].name
  role       = each.value.role
  member     = each.value.member
}
