# ========================================
# 로드 밸런서 모듈
# ========================================
module "load_balancer" {
  source = "../../modules/load-balancer"

  count = var.create_load_balancer ? 1 : 0

  name_prefix = "${var.project}-${var.environment}-nlb"
  region      = var.region
  lb_type     = var.lb_type

  # 헬스 체크 설정
  create_health_check              = true
  health_check_protocol            = var.lb_type == "NETWORK" ? "TCP" : (var.lb_type == "HTTPS" ? "HTTPS" : "HTTP")
  health_check_port                = var.lb_type == "HTTPS" ? 443 : 80
  health_check_request_path        = "/health"
  health_check_interval            = 5
  health_check_timeout             = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3

  # 백엔드 서비스 설정
  backend_protocol    = "TCP"
  backend_timeout_sec = 30
  session_affinity    = "CLIENT_IP"
  backend_groups = var.use_instance_group ? [
    merge(
      {
        group          = module.web_servers.instance_group_instance_group
        balancing_mode = var.lb_type == "NETWORK" ? "CONNECTION" : "UTILIZATION"
      },
      var.lb_type == "NETWORK" ? {} : {
        max_utilization = 0.8
      }
    )
  ] : []
  ssl_certificates = var.ssl_certificates

  # 포워딩 규칙 설정
  forwarding_rule_ip_protocol = "TCP"
  forwarding_rule_port_range  = var.lb_type == "HTTPS" ? "443" : "80"
  network_tier                = "PREMIUM"

  # HTTP(S) 로드 밸런서일 때만 CDN을 활성화합니다.
  enable_cdn = var.lb_type == "HTTP" || var.lb_type == "HTTPS" ? true : false
}
