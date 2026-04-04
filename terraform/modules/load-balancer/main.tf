# ========================================
# 리전 헬스 체크 리소스
# ========================================
resource "google_compute_region_health_check" "regional_health_check" {
  count = var.create_health_check ? 1 : 0

  name                = "${var.name_prefix}-health-check"
  region              = var.region
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  # HTTP 헬스 체크 설정입니다.
  dynamic "http_health_check" {
    for_each = var.health_check_protocol == "HTTP" ? [1] : []
    content {
      port         = var.health_check_port
      request_path = var.health_check_request_path
    }
  }

  # HTTPS 헬스 체크 설정입니다.
  dynamic "https_health_check" {
    for_each = var.health_check_protocol == "HTTPS" ? [1] : []
    content {
      port         = var.health_check_port
      request_path = var.health_check_request_path
    }
  }

  # TCP 헬스 체크 설정입니다.
  dynamic "tcp_health_check" {
    for_each = var.health_check_protocol == "TCP" ? [1] : []
    content {
      port = var.health_check_port
    }
  }

  # SSL 헬스 체크 설정입니다.
  dynamic "ssl_health_check" {
    for_each = var.health_check_protocol == "SSL" ? [1] : []
    content {
      port = var.health_check_port
    }
  }
}

locals {
  created_health_check_ids = google_compute_region_health_check.regional_health_check[*].id
}

# ========================================
# 네트워크 로드 밸런서 백엔드 서비스
# ========================================
resource "google_compute_region_backend_service" "backend_service" {
  name                  = "${var.name_prefix}-backend-service"
  region                = var.region
  protocol              = var.backend_protocol
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = var.backend_timeout_sec

  # 백엔드 그룹 정의입니다.
  dynamic "backend" {
    for_each = var.backend_groups
    content {
      group           = backend.value.group
      balancing_mode  = lookup(backend.value, "balancing_mode", "CONNECTION")
      capacity_scaler = lookup(backend.value, "capacity_scaler", 1.0)
    }
  }

  # 생성한 헬스 체크가 있으면 우선 사용합니다.
  health_checks = var.create_health_check ? local.created_health_check_ids : var.health_check_ids

  # 세션 어피니티 설정입니다.
  session_affinity = var.session_affinity

  # 선택적으로 연결 드레이닝 타임아웃을 적용합니다.
  connection_draining_timeout_sec = var.connection_draining_timeout

  lifecycle {
    precondition {
      condition = alltrue([
        for backend in var.backend_groups : lookup(backend, "balancing_mode", "CONNECTION") == "CONNECTION"
      ])
      error_message = "NETWORK 로드 밸런서의 backend_groups balancing_mode는 CONNECTION만 사용할 수 있습니다."
    }
  }
}

# ========================================
# 네트워크 로드 밸런서 포워딩 규칙
# ========================================
resource "google_compute_forwarding_rule" "forwarding_rule" {
  name                  = "${var.name_prefix}-forwarding-rule"
  region                = var.region
  ip_protocol           = var.forwarding_rule_ip_protocol
  load_balancing_scheme = "EXTERNAL"
  port_range            = var.forwarding_rule_port_range
  backend_service       = google_compute_region_backend_service.backend_service.id
  network_tier          = var.network_tier

  # 필요 시 고정 IP를 연결합니다.
  ip_address = var.forwarding_rule_ip_address
}
