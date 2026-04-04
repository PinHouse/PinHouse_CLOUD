# ========================================
# 헬스 체크 출력값
# ========================================
output "health_check_id" {
  description = "생성된 헬스 체크 ID입니다."
  value       = var.create_health_check ? google_compute_health_check.health_check[0].id : null
}

output "health_check_self_link" {
  description = "생성된 헬스 체크 self_link입니다."
  value       = var.create_health_check ? google_compute_health_check.health_check[0].self_link : null
}

# ========================================
# 네트워크 로드 밸런서 출력값
# ========================================
output "backend_service_id" {
  description = "생성된 네트워크 로드 밸런서 백엔드 서비스 ID입니다."
  value       = var.lb_type == "NETWORK" ? google_compute_region_backend_service.backend_service[0].id : null
}

output "backend_service_self_link" {
  description = "생성된 네트워크 로드 밸런서 백엔드 서비스 self_link입니다."
  value       = var.lb_type == "NETWORK" ? google_compute_region_backend_service.backend_service[0].self_link : null
}

# ========================================
# HTTP(S) 로드 밸런서 출력값
# ========================================
output "global_backend_service_id" {
  description = "생성된 HTTP(S) 글로벌 백엔드 서비스 ID입니다."
  value       = (var.lb_type == "HTTP" || var.lb_type == "HTTPS") ? google_compute_backend_service.global_backend_service[0].id : null
}

output "global_backend_service_self_link" {
  description = "생성된 HTTP(S) 글로벌 백엔드 서비스 self_link입니다."
  value       = (var.lb_type == "HTTP" || var.lb_type == "HTTPS") ? google_compute_backend_service.global_backend_service[0].self_link : null
}

# ========================================
# 공통 포워딩 규칙 출력값
# ========================================
output "forwarding_rule_ip_address" {
  description = "생성된 포워딩 규칙 IP 주소입니다."
  value = var.lb_type == "NETWORK" ? google_compute_forwarding_rule.forwarding_rule[0].ip_address : (
    var.lb_type == "HTTP" ? google_compute_global_forwarding_rule.http_forwarding_rule[0].ip_address : (
      var.lb_type == "HTTPS" ? google_compute_global_forwarding_rule.https_forwarding_rule[0].ip_address : null
    )
  )
}

output "forwarding_rule_self_link" {
  description = "생성된 포워딩 규칙 self_link입니다."
  value = var.lb_type == "NETWORK" ? google_compute_forwarding_rule.forwarding_rule[0].self_link : (
    var.lb_type == "HTTP" ? google_compute_global_forwarding_rule.http_forwarding_rule[0].self_link : (
      var.lb_type == "HTTPS" ? google_compute_global_forwarding_rule.https_forwarding_rule[0].self_link : null
    )
  )
}

# ========================================
# URL Map 및 프록시 출력값
# ========================================
output "url_map_id" {
  description = "생성된 URL Map ID입니다."
  value       = (var.lb_type == "HTTP" || var.lb_type == "HTTPS") ? google_compute_url_map.url_map[0].id : null
}

output "proxy_id" {
  description = "생성된 프록시 ID입니다."
  value = var.lb_type == "HTTP" ? google_compute_target_http_proxy.http_proxy[0].id : (
    var.lb_type == "HTTPS" ? google_compute_target_https_proxy.https_proxy[0].id : null
  )
}
