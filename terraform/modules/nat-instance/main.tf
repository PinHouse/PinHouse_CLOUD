# ========================================
# NAT 인스턴스 리소스
# ========================================
resource "google_compute_instance" "nat_instance" {
  name         = "${var.name_prefix}-instance"
  zone         = var.zone
  machine_type = var.machine_type

  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = var.source_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    access_config {
      network_tier = var.network_tier
    }
  }

  metadata = merge(
    {
      enable-oslogin = "TRUE"
    },
    var.metadata
  )

  # 부팅 시 IP 포워딩과 MASQUERADE 규칙을 다시 적용합니다.
  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    PRIMARY_IF="$(ip route show default | awk '/default/ {print $5}' | head -n1)"
    if [ -z "$PRIMARY_IF" ]; then
      PRIMARY_IF="ens4"
    fi

    cat >/etc/sysctl.d/99-nat-instance.conf <<'EOF'
    net.ipv4.ip_forward=1
    EOF

    sysctl --system

    iptables -t nat -C POSTROUTING -o "$PRIMARY_IF" -j MASQUERADE || iptables -t nat -A POSTROUTING -o "$PRIMARY_IF" -j MASQUERADE
    iptables -C FORWARD -i "$PRIMARY_IF" -o "$PRIMARY_IF" -j ACCEPT || iptables -A FORWARD -i "$PRIMARY_IF" -o "$PRIMARY_IF" -j ACCEPT
    iptables -C FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT || iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  EOT

  dynamic "service_account" {
    for_each = var.service_account_email != null ? [var.service_account_email] : []
    content {
      email  = service_account.value
      scopes = var.service_account_scopes
    }
  }

  tags = concat(var.tags, [var.nat_instance_tag])
  labels = {
    for k, v in var.common_tags : lower(k) => lower(v)
  }

  allow_stopping_for_update = true
}

# ========================================
# NAT 인스턴스 방화벽 리소스
# ========================================
resource "google_compute_firewall" "allow_internal_to_nat" {
  name    = "${var.name_prefix}-allow-internal"
  network = var.network

  description = "내부 인스턴스가 NAT 인스턴스를 경유해 외부로 나갈 수 있도록 허용합니다."
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = var.internal_source_ranges
  target_tags   = [var.nat_instance_tag]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
}

# ========================================
# NAT 인스턴스 경로 리소스
# ========================================
resource "google_compute_route" "default_via_nat" {
  name    = "${var.name_prefix}-default-route"
  network = var.network

  dest_range             = var.route_destination_range
  priority               = var.route_priority
  next_hop_instance      = google_compute_instance.nat_instance.self_link
  next_hop_instance_zone = var.zone
  tags                   = var.route_tags
}
