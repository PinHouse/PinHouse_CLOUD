# ========================================
# 로드 밸런서 모듈
# ========================================
module "load_balancer" {
  source = "../../modules/load-balancer"

  count = var.create_load_balancer ? 1 : 0

  name_prefix = "${var.environment}-lb"
  region      = var.region

  # 헬스 체크 설정
  create_health_check              = true
  health_check_protocol            = "TCP"
  health_check_port                = 80
  health_check_request_path        = "/"
  health_check_interval            = 10
  health_check_timeout             = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2

  # 백엔드 서비스 설정
  backend_protocol    = "TCP"
  backend_timeout_sec = 30

  # 포워딩 규칙 설정
  forwarding_rule_ip_protocol = "TCP"
  forwarding_rule_port_range  = "80"
  network_tier                = "PREMIUM"
}
