# ========================================
# Secret Manager 출력값
# ========================================
output "secrets" {
  description = "생성된 Secret Manager secret 정보입니다."
  value = {
    for key, value in google_secret_manager_secret.secrets : key => {
      id        = value.id
      name      = value.name
      secret_id = value.secret_id
    }
  }
}

output "secret_ids" {
  description = "생성된 Secret Manager secret ID 목록입니다."
  value       = sort(keys(google_secret_manager_secret.secrets))
}
