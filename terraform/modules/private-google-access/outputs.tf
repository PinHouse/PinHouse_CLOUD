# ========================================
# Private Google Access 출력값
# ========================================
output "google_api_domain_option" {
  description = "적용된 Google API 도메인 옵션입니다."
  value       = var.google_api_domain_option
}

output "googleapis_private_zone_name" {
  description = "생성된 googleapis.com Private DNS zone 이름입니다."
  value       = google_dns_managed_zone.googleapis_private_zone.name
}

output "pkg_dev_private_zone_name" {
  description = "생성된 pkg.dev Private DNS zone 이름입니다."
  value       = google_dns_managed_zone.pkg_dev_private_zone.name
}

output "google_api_route_name" {
  description = "생성된 Google API VIP 라우트 이름입니다."
  value       = google_compute_route.google_api_vip_route.name
}

output "google_api_direct_connectivity_route_name" {
  description = "생성된 Google 직접 연결 대역 라우트 이름입니다."
  value       = var.create_direct_connectivity_route ? google_compute_route.google_api_direct_connectivity_route[0].name : null
}
