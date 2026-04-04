# ========================================
# 인스턴스 템플릿 리소스
# ========================================
resource "google_compute_instance_template" "template" {
  count = var.create_instance_template ? 1 : 0

  name_prefix  = "${var.name_prefix}-template-"
  description  = var.template_description
  machine_type = var.machine_type

  # 부팅 디스크 설정입니다.
  disk {
    source_image = var.source_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.boot_disk_size_gb
    disk_type    = var.boot_disk_type
  }

  # 네트워크 인터페이스 설정입니다.
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    # 외부 IP가 필요한 경우에만 access_config를 생성합니다.
    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        nat_ip       = null
        network_tier = var.network_tier
      }
    }
  }

  # 공통 메타데이터를 구성합니다.
  metadata = merge(
    {
      enable-oslogin = var.enable_os_login
    },
    var.metadata
  )

  # 시작 스크립트입니다.
  metadata_startup_script = var.startup_script

  # 서비스 계정 설정입니다.
  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  # 네트워크 태그입니다.
  tags = var.tags

  # 공통 레이블입니다.
  labels = var.labels

  # 선점형 인스턴스일 때 스케줄링 정책을 조정합니다.
  scheduling {
    automatic_restart   = !var.preemptible
    on_host_maintenance = var.preemptible ? "TERMINATE" : "MIGRATE"
    preemptible         = var.preemptible
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ========================================
# 개별 인스턴스 리소스
# ========================================
resource "google_compute_instance" "instances" {
  for_each = var.instances

  name         = each.value.name
  machine_type = lookup(each.value, "machine_type", var.machine_type)
  zone         = each.value.zone

  # 인스턴스별 부팅 디스크 설정입니다.
  boot_disk {
    initialize_params {
      image = lookup(each.value, "source_image", var.source_image)
      size  = lookup(each.value, "boot_disk_size_gb", var.boot_disk_size_gb)
      type  = lookup(each.value, "boot_disk_type", var.boot_disk_type)
    }
  }

  # 네트워크 인터페이스 설정입니다.
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    # 외부 IP가 필요한 인스턴스에만 access_config를 생성합니다.
    dynamic "access_config" {
      for_each = lookup(each.value, "enable_external_ip", var.enable_external_ip) ? [1] : []
      content {
        nat_ip       = lookup(each.value, "external_ip", null)
        network_tier = var.network_tier
      }
    }
  }

  # 공통 메타데이터와 인스턴스별 메타데이터를 병합합니다.
  metadata = merge(
    {
      enable-oslogin = var.enable_os_login
    },
    var.metadata,
    lookup(each.value, "metadata", {})
  )

  # 인스턴스별 시작 스크립트를 우선 적용합니다.
  metadata_startup_script = lookup(each.value, "startup_script", var.startup_script)

  # 서비스 계정 설정입니다.
  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  # 공통 태그와 인스턴스별 태그를 합칩니다.
  tags = concat(var.tags, lookup(each.value, "tags", []))

  # 공통 레이블과 인스턴스별 레이블을 합칩니다.
  labels = merge(var.labels, lookup(each.value, "labels", {}))

  # 선점형 여부에 따라 스케줄링 정책을 조정합니다.
  scheduling {
    automatic_restart   = !var.preemptible
    on_host_maintenance = var.preemptible ? "TERMINATE" : "MIGRATE"
    preemptible         = var.preemptible
  }

  # 개별 인스턴스 삭제 방지 여부입니다.
  deletion_protection = lookup(each.value, "deletion_protection", false)

  allow_stopping_for_update = true
}

# ========================================
# 관리형 인스턴스 그룹 리소스
# ========================================
resource "google_compute_instance_group_manager" "instance_group" {
  count = var.create_instance_group ? 1 : 0

  name               = "${var.name_prefix}-ig"
  base_instance_name = var.name_prefix
  zone               = var.instance_group_zone

  version {
    instance_template = google_compute_instance_template.template[0].id
  }

  # 인스턴스 그룹 목표 크기입니다.
  target_size = var.instance_group_target_size

  # 헬스 체크가 전달된 경우 자동 복구 정책을 추가합니다.
  dynamic "auto_healing_policies" {
    for_each = var.health_check_name != null ? [1] : []
    content {
      health_check      = var.health_check_name
      initial_delay_sec = var.health_check_initial_delay
    }
  }

  # 애플리케이션 포트를 Named Port로 노출합니다.
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }

  # 배포 업데이트 정책입니다.
  update_policy {
    type                  = var.update_policy_type
    minimal_action        = var.update_minimal_action
    max_surge_fixed       = var.max_surge_fixed
    max_unavailable_fixed = var.max_unavailable_fixed
  }
}

# ========================================
# 오토스케일러 리소스
# ========================================
resource "google_compute_autoscaler" "autoscaler" {
  count = var.enable_autoscaling ? 1 : 0

  name   = "${var.name_prefix}-autoscaler"
  zone   = var.instance_group_zone
  target = google_compute_instance_group_manager.instance_group[0].id

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = var.autoscaling_cooldown_period

    # CPU 사용률 목표가 있을 때만 CPU 기반 정책을 추가합니다.
    dynamic "cpu_utilization" {
      for_each = var.autoscaling_cpu_target != null ? [1] : []
      content {
        target = var.autoscaling_cpu_target
      }
    }
  }
}
