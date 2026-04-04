# ========================================
# 인스턴스 템플릿 출력값
# ========================================
output "instance_template_id" {
  description = "생성된 인스턴스 템플릿 ID입니다."
  value       = var.create_instance_template ? google_compute_instance_template.template[0].id : null
}

output "instance_template_self_link" {
  description = "생성된 인스턴스 템플릿 self_link입니다."
  value       = var.create_instance_template ? google_compute_instance_template.template[0].self_link : null
}

# ========================================
# 개별 인스턴스 출력값
# ========================================
output "instances" {
  description = "생성된 인스턴스 정보입니다."
  value = {
    for k, v in google_compute_instance.instances : k => {
      id           = v.id
      name         = v.name
      zone         = v.zone
      self_link    = v.self_link
      instance_id  = v.instance_id
      cpu_platform = v.cpu_platform
      internal_ip  = v.network_interface[0].network_ip
      external_ip  = length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : null
    }
  }
}

# ========================================
# 관리형 인스턴스 그룹 출력값
# ========================================
output "instance_group_id" {
  description = "생성된 관리형 인스턴스 그룹 ID입니다."
  value       = var.create_instance_group ? google_compute_instance_group_manager.instance_group[0].id : null
}

output "instance_group_self_link" {
  description = "생성된 관리형 인스턴스 그룹 self_link입니다."
  value       = var.create_instance_group ? google_compute_instance_group_manager.instance_group[0].self_link : null
}

output "instance_group_instance_group" {
  description = "관리형 인스턴스 그룹이 참조하는 인스턴스 그룹 self_link입니다."
  value       = var.create_instance_group ? google_compute_instance_group_manager.instance_group[0].instance_group : null
}

# ========================================
# 오토스케일러 출력값
# ========================================
output "autoscaler_id" {
  description = "생성된 오토스케일러 ID입니다."
  value       = var.enable_autoscaling ? google_compute_autoscaler.autoscaler[0].id : null
}
