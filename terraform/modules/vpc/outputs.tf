# ========================================
# VPC 출력값
# ========================================
output "vpc_id" {
  description = "생성된 VPC 네트워크 ID입니다."
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "생성된 VPC 네트워크 이름입니다."
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "생성된 VPC 네트워크 self_link입니다."
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "생성된 서브넷 정보입니다."
  value = {
    for k, v in google_compute_subnetwork.subnets : k => {
      id            = v.id
      name          = v.name
      ip_cidr_range = v.ip_cidr_range
      region        = v.region
      self_link     = v.self_link
    }
  }
}

# ========================================
# Cloud NAT 출력값
# ========================================
output "router_name" {
  description = "생성된 Cloud Router 이름입니다."
  value       = var.enable_nat ? google_compute_router.router[0].name : null
}

output "nat_name" {
  description = "생성된 Cloud NAT 이름입니다."
  value       = var.enable_nat ? google_compute_router_nat.nat[0].name : null
}
