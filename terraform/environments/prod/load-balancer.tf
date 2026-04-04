# ========================================
# 로드 밸런서 모듈
# ========================================
module "load_balancer" {
  source = "../../modules/load-balancer"

  count = var.create_load_balancer ? 1 : 0

  name_prefix = "${var.project}-${var.environment}-nlb"
  region      = var.region

  # 헬스 체크 설정
  create_health_check              = true
  health_check_protocol            = "TCP"
  health_check_port                = 80
  health_check_request_path        = "/health"
  health_check_interval            = 5
  health_check_timeout             = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3

  # 백엔드 서비스 설정
  backend_protocol    = "TCP"
  backend_timeout_sec = 30
  session_affinity    = "CLIENT_IP"
  backend_groups = [
    {
      group          = module.k8s_worker_nodes.instance_group_instance_group
      balancing_mode = "CONNECTION"
    }
  ]

  # 포워딩 규칙 설정
  forwarding_rule_ip_protocol = "TCP"
  forwarding_rule_port_range  = "80"
  network_tier                = "PREMIUM"
}
