#!/usr/bin/env bash
set -euxo pipefail

# ========================================
# 기본 환경 점검
# ========================================
if [ "$(id -u)" -ne 0 ]; then
  echo "이 스크립트는 root 권한으로 실행해야 합니다."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ========================================
# Ubuntu 기본 패키지 업데이트
# ========================================
apt-get update -y
apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl gpg containerd

# ========================================
# swap 비활성화
# ========================================
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# ========================================
# Kubernetes 네트워크용 커널 모듈 및 sysctl 설정
# ========================================
mkdir -p /etc/modules-load.d /etc/sysctl.d /etc/apt/keyrings /etc/containerd

cat <<'EOF' >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<'EOF' >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# ========================================
# containerd 설정
# ========================================
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl daemon-reload
systemctl enable --now containerd

# ========================================
# Kubernetes apt 저장소 설정
# ========================================
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' >/etc/apt/sources.list.d/kubernetes.list

# ========================================
# Kubernetes 패키지 설치
# ========================================
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ========================================
# kubelet Artifact Registry credential provider 설정
# ========================================
mkdir -p /etc/kubernetes /opt/image-credential-provider

cat <<'PROVIDER_EOF' >/opt/image-credential-provider/gcp-artifact-registry-provider
#!/usr/bin/env bash
set -euo pipefail

# kubelet 요청 본문은 현재 인증 계산에 사용하지 않으므로 읽고 종료합니다.
cat >/dev/null

token_response="$(curl -fsSL -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token)"
access_token="$(printf '%s' "${token_response}" | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

if [ -z "${access_token}" ]; then
  echo "메타데이터 서버에서 Artifact Registry access token을 가져오지 못했습니다." >&2
  exit 1
fi

cat <<JSON_EOF
{
  "apiVersion": "credentialprovider.kubelet.k8s.io/v1",
  "kind": "CredentialProviderResponse",
  "cacheKeyType": "Registry",
  "auth": {
    "*.pkg.dev": {
      "username": "oauth2accesstoken",
      "password": "${access_token}"
    }
  }
}
JSON_EOF
PROVIDER_EOF

chmod 0755 /opt/image-credential-provider/gcp-artifact-registry-provider

cat <<'EOF' >/etc/kubernetes/credential-provider-config.yaml
apiVersion: kubelet.config.k8s.io/v1
kind: CredentialProviderConfig
providers:
  - name: gcp-artifact-registry-provider
    apiVersion: credentialprovider.kubelet.k8s.io/v1
    matchImages:
      - "*.pkg.dev"
    defaultCacheDuration: "30m"
EOF

cat <<'EOF' >/etc/default/kubelet
KUBELET_EXTRA_ARGS="--image-credential-provider-config=/etc/kubernetes/credential-provider-config.yaml --image-credential-provider-bin-dir=/opt/image-credential-provider"
EOF

# ========================================
# 서비스 활성화
# ========================================
systemctl enable --now kubelet

# ========================================
# kubeadm 및 Calico 초기 설정 파일 생성
# ========================================
cat <<EOF >/root/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
networking:
  podSubnet: ${k8s_pod_cidr}
  serviceSubnet: ${k8s_service_cidr}
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

cat <<EOF >/root/calico-custom-resources.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
      - blockSize: 26
        cidr: ${k8s_pod_cidr}
        encapsulation: IPIP
        natOutgoing: Enabled
        nodeSelector: all()
EOF

cat <<EOF >/root/install-calico.sh
#!/usr/bin/env bash
set -euxo pipefail

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${calico_version}/manifests/operator-crds.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${calico_version}/manifests/tigera-operator.yaml
kubectl create -f /root/calico-custom-resources.yaml
EOF

chmod +x /root/install-calico.sh

# ========================================
# 후속 작업 안내
# ========================================
echo "마스터 노드 초기 설정이 완료되었습니다."
echo "1. kubeadm init --config /root/kubeadm-config.yaml --upload-certs"
echo "2. mkdir -p \$HOME/.kube && cp /etc/kubernetes/admin.conf \$HOME/.kube/config && chown \$(id -u):\$(id -g) \$HOME/.kube/config"
echo "3. /root/install-calico.sh"
