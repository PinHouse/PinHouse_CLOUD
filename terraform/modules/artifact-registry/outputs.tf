# ========================================
# Artifact Registry 출력값
# ========================================
output "repositories" {
  description = "생성된 Artifact Registry 저장소 정보입니다."
  value = {
    for k, v in google_artifact_registry_repository.repositories : k => {
      id            = v.id
      name          = v.name
      repository_id = v.repository_id
      location      = v.location
      format        = v.format
    }
  }
}

output "docker_repository_urls" {
  description = "Docker 형식 저장소의 푸시/풀 URL 목록입니다."
  value = {
    for k, v in google_artifact_registry_repository.repositories :
    k => "${v.location}-docker.pkg.dev/${var.project_id}/${v.repository_id}"
    if v.format == "DOCKER"
  }
}
