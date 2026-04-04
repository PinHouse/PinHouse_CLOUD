# ========================================
# VPC 출력값
# ========================================
output "vpc_id" {
  description = "생성된 VPC 네트워크 ID입니다."
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "생성된 VPC 네트워크 이름입니다."
  value       = module.vpc.vpc_name
}

output "subnets" {
  description = "생성된 서브넷 정보입니다."
  value       = module.vpc.subnets
}

# ========================================
# 웹 서버 출력값
# ========================================
output "web_instances" {
  description = "생성된 웹 인스턴스 정보입니다."
  value       = module.web_servers.instances
}

output "instance_group_id" {
  description = "생성된 인스턴스 그룹 ID입니다."
  value       = module.web_servers.instance_group_id
}

# ========================================
# 스토리지 출력값
# ========================================
output "storage_buckets" {
  description = "생성된 스토리지 버킷 정보입니다."
  value       = module.storage.buckets
}

output "bucket_urls" {
  description = "생성된 버킷 URL 목록입니다."
  value       = module.storage.bucket_urls
}

# ========================================
# 로드 밸런서 출력값
# ========================================
output "load_balancer_ip" {
  description = "로드 밸런서 IP 주소입니다."
  value       = var.create_load_balancer ? module.load_balancer[0].forwarding_rule_ip_address : null
}
