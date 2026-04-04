# ========================================
# IAP 접근 출력값
# ========================================
output "iap_access_members" {
  description = "IAP 터널 접근 권한이 부여된 IAM 주체 목록입니다."
  value       = sort(tolist(local.iap_access_members))
}

output "iap_admin_members" {
  description = "관리자 OS Login 권한이 부여된 IAM 주체 목록입니다."
  value       = sort(tolist(toset(var.iap_ssh_admin_members)))
}
