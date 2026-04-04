# ========================================
# 헬스 체크 출력값
# ========================================
output "health_check_id" {
  description = "생성된 헬스 체크 ID입니다."
  value       = var.create_health_check ? google_compute_region_health_check.regional_health_check[0].id : null
}

output "health_check_self_link" {
  description = "생성된 헬스 체크 self_link입니다."
  value       = var.create_health_check ? google_compute_region_health_check.regional_health_check[0].self_link : null
}

# ========================================
# 네트워크 로드 밸런서 출력값
# ========================================
output "backend_service_id" {
  description = "생성된 네트워크 로드 밸런서 백엔드 서비스 ID입니다."
  value       = google_compute_region_backend_service.backend_service.id
}

output "backend_service_self_link" {
  description = "생성된 네트워크 로드 밸런서 백엔드 서비스 self_link입니다."
  value       = google_compute_region_backend_service.backend_service.self_link
}

# ========================================
# 공통 포워딩 규칙 출력값
# ========================================
output "forwarding_rule_ip_address" {
  description = "생성된 포워딩 규칙 IP 주소입니다."
  value       = google_compute_forwarding_rule.forwarding_rule.ip_address
}

output "forwarding_rule_self_link" {
  description = "생성된 포워딩 규칙 self_link입니다."
  value       = google_compute_forwarding_rule.forwarding_rule.self_link
}
