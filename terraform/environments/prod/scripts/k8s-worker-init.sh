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
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

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
# 후속 작업 안내
# ========================================
echo "워커 노드 초기 설정이 완료되었습니다. 이후 kubeadm join 명령을 실행하세요."
