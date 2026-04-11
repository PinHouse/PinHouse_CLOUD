# ========================================
# 개발 환경 방화벽 규칙
# ========================================
locals {
  gcp_load_balancer_health_check_source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  dev_firewall_rules = merge(
    var.create_load_balancer ? {
      # 외부 프록시 NLB와 헬스 체크가 워커 NodePort로 접근할 수 있도록 허용합니다.
      allow_nginx_gateway_nodeports = {
        name = "${var.vpc_name}-allow-nginx-gateway-nodeports"
        allow = [
          {
            protocol = "tcp"
            ports = [
              tostring(var.nginx_gateway_http_node_port),
              tostring(var.nginx_gateway_https_node_port),
            ]
          }
        ]
        source_ranges = concat(
          local.gcp_load_balancer_health_check_source_ranges,
          [var.load_balancer_proxy_only_subnet_cidr]
        )
        target_tags = ["k8s-worker"]
        priority    = 1000
      }
    } : {},
    {
      # 마스터와 워커 노드가 Kubernetes API 서버에 접근할 수 있도록 허용합니다.
      allow_k8s_api_from_nodes = {
        name = "${var.vpc_name}-allow-k8s-api-from-nodes"
        allow = [
          {
            protocol = "tcp"
            ports    = ["6443"]
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master"]
        priority    = 1000
      }

      # 마스터 노드 간 etcd와 컨트롤 플레인 포트를 허용합니다.
      allow_k8s_control_plane = {
        name = "${var.vpc_name}-allow-k8s-control-plane"
        allow = [
          {
            protocol = "tcp"
            ports    = ["2379-2380", "10250", "10257", "10259"]
          }
        ]
        source_tags = ["k8s-master"]
        target_tags = ["k8s-master"]
        priority    = 1000
      }

      # 마스터 노드가 워커 노드 kubelet에 접근할 수 있도록 허용합니다.
      allow_kubelet_from_control_plane = {
        name = "${var.vpc_name}-allow-kubelet-from-control-plane"
        allow = [
          {
            protocol = "tcp"
            ports    = ["10250"]
          }
        ]
        source_tags = ["k8s-master"]
        target_tags = ["k8s-worker"]
        priority    = 1000
      }

      # 노드 간 kube-proxy 헬스 및 프록시 포트를 허용합니다.
      allow_kube_proxy_from_nodes = {
        name = "${var.vpc_name}-allow-kube-proxy-from-nodes"
        allow = [
          {
            protocol = "tcp"
            ports    = ["10256"]
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-worker"]
        priority    = 1000
      }

      # Calico BGP 피어링에 필요한 TCP 179 포트를 허용합니다.
      allow_calico_bgp = {
        name = "${var.vpc_name}-allow-calico-bgp"
        allow = [
          {
            protocol = "tcp"
            ports    = ["179"]
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master", "k8s-worker"]
        priority    = 1000
      }

      # Calico VXLAN 터널링 트래픽을 허용합니다.
      allow_calico_vxlan = {
        name = "${var.vpc_name}-allow-calico-vxlan"
        allow = [
          {
            protocol = "udp"
            ports    = ["4789"]
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master", "k8s-worker"]
        priority    = 1000
      }

      # Pod CIDR 대역에서 노드로 들어오는 Calico 워크로드 트래픽을 허용합니다.
      allow_calico_pod_cidr = {
        name = "${var.vpc_name}-allow-calico-pod-cidr"
        allow = [
          {
            protocol = "tcp"
            ports    = ["0-65535"]
          },
          {
            protocol = "udp"
            ports    = ["0-65535"]
          },
          {
            protocol = "icmp"
          }
        ]
        source_ranges = [var.k8s_pod_cidr]
        target_tags   = ["k8s-master", "k8s-worker"]
        priority      = 1000
      }
    },
    var.enable_iap_ssh ? {
      # IAP TCP 터널을 통한 SSH 접근을 허용합니다.
      allow_iap_ssh = {
        name = "${var.vpc_name}-allow-iap-ssh"
        allow = [
          {
            protocol = "tcp"
            ports    = ["22"]
          }
        ]
        source_ranges = var.iap_ssh_source_ranges
        target_tags   = var.management_target_tags
        priority      = 1000
      }
    } : {},
    {
      # Kubernetes 노드 태그를 가진 인스턴스끼리 내부 통신을 허용합니다.
      allow_internal = {
        name = "${var.vpc_name}-allow-internal"
        allow = [
          {
            protocol = "tcp"
            ports    = ["0-65535"]
          },
          {
            protocol = "udp"
            ports    = ["0-65535"]
          },
          {
            protocol = "icmp"
          }
        ]
        source_tags = ["k8s-master", "k8s-worker"]
        target_tags = ["k8s-master", "k8s-worker"]
        priority    = 65534
      }
    }
  )
}
