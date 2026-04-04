# ========================================
# NAT 인스턴스 출력값
# ========================================
output "instance_name" {
  description = "생성된 NAT 인스턴스 이름입니다."
  value       = google_compute_instance.nat_instance.name
}

output "instance_self_link" {
  description = "생성된 NAT 인스턴스 self_link입니다."
  value       = google_compute_instance.nat_instance.self_link
}

output "external_ip" {
  description = "생성된 NAT 인스턴스 외부 IP 주소입니다."
  value       = google_compute_instance.nat_instance.network_interface[0].access_config[0].nat_ip
}

output "route_name" {
  description = "생성된 NAT 인스턴스 기본 경로 이름입니다."
  value       = google_compute_route.default_via_nat.name
}

output "route_tags" {
  description = "NAT 인스턴스 경로를 타기 위해 필요한 인스턴스 태그 목록입니다."
  value       = var.route_tags
}

output "nat_instance_tag" {
  description = "NAT 인스턴스 자체에 부여된 태그입니다."
  value       = var.nat_instance_tag
}
