# ========================================
# 글로벌 헬스 체크 리소스
# ========================================
resource "google_compute_health_check" "health_check" {
  count = var.create_health_check && var.lb_type != "NETWORK" ? 1 : 0

  name                = "${var.name_prefix}-health-check"
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

# ========================================
# 리전 헬스 체크 리소스
# ========================================
resource "google_compute_region_health_check" "regional_health_check" {
  count = var.create_health_check && var.lb_type == "NETWORK" ? 1 : 0

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
  created_health_check_ids = var.lb_type == "NETWORK" ? google_compute_region_health_check.regional_health_check[*].id : google_compute_health_check.health_check[*].id
}

# ========================================
# 네트워크 로드 밸런서 백엔드 서비스
# ========================================
resource "google_compute_region_backend_service" "backend_service" {
  count = var.lb_type == "NETWORK" ? 1 : 0

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
}

# ========================================
# 네트워크 로드 밸런서 포워딩 규칙
# ========================================
resource "google_compute_forwarding_rule" "forwarding_rule" {
  count = var.lb_type == "NETWORK" ? 1 : 0

  name                  = "${var.name_prefix}-forwarding-rule"
  region                = var.region
  ip_protocol           = var.forwarding_rule_ip_protocol
  load_balancing_scheme = "EXTERNAL"
  port_range            = var.forwarding_rule_port_range
  backend_service       = google_compute_region_backend_service.backend_service[0].id
  network_tier          = var.network_tier

  # 필요 시 고정 IP를 연결합니다.
  ip_address = var.forwarding_rule_ip_address
}

# ========================================
# HTTP(S) 글로벌 백엔드 서비스
# ========================================
resource "google_compute_backend_service" "global_backend_service" {
  count = var.lb_type == "HTTP" || var.lb_type == "HTTPS" ? 1 : 0

  name                  = "${var.name_prefix}-backend-service"
  protocol              = var.lb_type
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = var.backend_timeout_sec
  enable_cdn            = var.enable_cdn

  # 백엔드 그룹 정의입니다.
  dynamic "backend" {
    for_each = var.backend_groups
    content {
      group           = backend.value.group
      balancing_mode  = lookup(backend.value, "balancing_mode", "UTILIZATION")
      capacity_scaler = lookup(backend.value, "capacity_scaler", 1.0)
      max_utilization = lookup(backend.value, "max_utilization", 0.8)
    }
  }

  # 생성한 헬스 체크가 있으면 우선 사용합니다.
  health_checks = var.create_health_check ? local.created_health_check_ids : var.health_check_ids

  # 세션 어피니티 설정입니다.
  session_affinity = var.session_affinity

  # CDN이 활성화된 경우에만 CDN 정책을 추가합니다.
  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode        = var.cdn_cache_mode
      default_ttl       = var.cdn_default_ttl
      max_ttl           = var.cdn_max_ttl
      client_ttl        = var.cdn_client_ttl
      negative_caching  = var.cdn_negative_caching
      serve_while_stale = var.cdn_serve_while_stale

      cache_key_policy {
        include_host         = true
        include_protocol     = true
        include_query_string = true
      }
    }
  }
}

# ========================================
# URL Map 리소스
# ========================================
resource "google_compute_url_map" "url_map" {
  count = var.lb_type == "HTTP" || var.lb_type == "HTTPS" ? 1 : 0

  name            = "${var.name_prefix}-url-map"
  default_service = google_compute_backend_service.global_backend_service[0].id
}

# ========================================
# HTTP 프록시 리소스
# ========================================
resource "google_compute_target_http_proxy" "http_proxy" {
  count = var.lb_type == "HTTP" ? 1 : 0

  name    = "${var.name_prefix}-http-proxy"
  url_map = google_compute_url_map.url_map[0].id
}

# ========================================
# HTTPS 프록시 리소스
# ========================================
resource "google_compute_target_https_proxy" "https_proxy" {
  count = var.lb_type == "HTTPS" ? 1 : 0

  name             = "${var.name_prefix}-https-proxy"
  url_map          = google_compute_url_map.url_map[0].id
  ssl_certificates = var.ssl_certificates
}

# ========================================
# HTTP 글로벌 포워딩 규칙
# ========================================
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  count = var.lb_type == "HTTP" ? 1 : 0

  name                  = "${var.name_prefix}-http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy[0].id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = var.forwarding_rule_ip_address
}

# ========================================
# HTTPS 글로벌 포워딩 규칙
# ========================================
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  count = var.lb_type == "HTTPS" ? 1 : 0

  name                  = "${var.name_prefix}-https-forwarding-rule"
  target                = google_compute_target_https_proxy.https_proxy[0].id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = var.forwarding_rule_ip_address
}
