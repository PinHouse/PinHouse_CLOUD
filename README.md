# PinHouse Cloud

PinHouse 서비스의 클라우드 인프라와 Kubernetes 플랫폼 운영 기준을 코드로 관리하는 레포지토리입니다.

이 레포지토리는 단순히 리소스를 생성하는 Terraform 저장소가 아니라,
인프라 계층, 플랫폼 계층, 배포 계층의 책임을 분리해 운영 가능한 구조로 정리한 것이 핵심입니다.

## 저장소 구조

```text
.
├── terraform/
│   ├── modules/              # 재사용 가능한 인프라 모듈
│   └── environments/         # dev, staging, prod 환경별 루트 구성
├── k8s-helm/
│   ├── platform-chart/       # Gateway, Certificate, ExternalSecret 등 플랫폼 공통 리소스
│   └── releases/             # NGINX Gateway Fabric, External Secrets Operator 등 컨트롤러 release 값
├── k8s-argocd/               # Argo CD Application 선언
├── k8s-kustomize/            # 애플리케이션 기본 매니페스트
└── .github/workflows/        # Terraform plan/apply 자동화
```


## 무엇을 관리하는가

- GCP 기반 네트워크, 컴퓨트, 로드밸런서, 스토리지, Artifact Registry 같은 인프라 리소스
- Kubernetes 클러스터에서 공통으로 필요한 Gateway, Certificate, NetworkPolicy, ExternalSecret 같은 플랫폼 리소스
- Argo CD와 GitHub Actions를 이용한 선언형 배포 흐름
- 환경별 설정 분리와 보안 기준

## 아키텍처 관점

이 저장소는 세 개의 계층으로 나뉩니다.

### 1. Infrastructure Layer

Terraform이 담당합니다.

- VPC, 서브넷, 컴퓨트, 로드밸런서, 스토리지 같은 기반 인프라를 선언적으로 관리합니다.
- 환경은 `dev`, `staging`, `prod`로 분리하고, 공통 모듈은 `terraform/modules`에 둡니다.
- Artifact Registry, Private Google Access 같은 운영에 필요한 기반 리소스도 이 계층에서 관리합니다.

### 2. Platform Layer

Helm이 담당합니다.

- 컨트롤러 설치와 플랫폼 리소스 생성을 분리합니다.
- 예를 들어 NGINX Gateway Fabric release는 컨트롤러와 `GatewayClass`를 소유하고,
  `platform-chart`는 실제 `Gateway`, `Certificate`, `ExternalSecret`, `NetworkPolicy`를 생성합니다.
- 이 구조를 통해 “컨트롤러 운영”과 “플랫폼 정책/구성”의 변경 단위를 분리합니다.

### 3. Delivery Layer

Argo CD와 GitHub Actions가 담당합니다.

- GitHub Actions는 인프라 변경에 대해 plan/apply 흐름을 제공합니다.
- Argo CD는 클러스터 내부 애플리케이션 선언을 지속적으로 동기화합니다.
- 결과적으로 인프라는 Terraform, 클러스터 플랫폼은 Helm, 애플리케이션 배포는 Argo CD가 맡는 구조입니다.

## 이 구조를 택한 이유

이 저장소의 핵심 설계 원칙은 책임 분리입니다.

- Terraform은 “클라우드 자원”을 관리합니다.
- Helm release는 “컨트롤러 설치”를 관리합니다.
- `platform-chart`는 “클러스터 공통 정책과 플랫폼 리소스”를 관리합니다.
- Argo CD는 “애플리케이션 선언과 배포 상태”를 관리합니다.

이렇게 나누면 다음 이점이 있습니다.

- 어떤 변경이 인프라 변경인지, 플랫폼 정책 변경인지, 앱 배포 변경인지 구분이 명확합니다.
- 환경별 차이를 values/variables 수준에서 통제할 수 있습니다.
- 운영 중 장애나 변경 이슈가 생겼을 때 책임 범위를 빠르게 좁힐 수 있습니다.

## 환경 분리 전략

환경은 `dev`, `staging`, `prod` 기준으로 나뉘며, 각 환경은 서로 다른 운영 목적을 가집니다.

- `dev`: 기능 검증과 빠른 반복
- `staging`: 운영 전 검증과 통합 테스트
- `prod`: 실제 서비스 운영

같은 구조를 유지하되, 환경별 값만 다르게 가져가는 방식을 기본 원칙으로 삼았습니다.
즉, 구조는 공통화하고 값은 분리하는 방식입니다.

## Secret 관리 방식

시크릿은 GCP Secret Manager를 기준으로 운영합니다.

중요한 점은 GCP Secret Manager가 `/Prod/BE/DB_URL` 같은 계층형 path를 지원하지 않는다는 것입니다.
그래서 이 저장소에서는 다음과 같은 flat prefix 규칙을 사용합니다.

- `Prod_BE_DB_URL`
- `Prod_BE_DB_PASSWORD`
- `Stg_BE_REDIS_HOST`

External Secrets Operator는 이 prefix 규칙을 기반으로 secret들을 한 번에 찾고,
`rewrite`를 통해 prefix를 제거한 뒤 Kubernetes Secret으로 변환합니다.

예를 들어 `Prod_BE_*`를 가져오면 Kubernetes 내부에서는 `DB_URL`, `DB_PASSWORD` 같은 key로 사용됩니다.

이 방식의 장점은 다음과 같습니다.

- GCP Secret Manager 제약을 우회하지 않고, 서비스/환경 구분을 유지할 수 있습니다.
- 서비스별로 시크릿 집합을 일관된 규칙으로 확장하기 쉽습니다.

## 보안 원칙

- Terraform state는 GCS remote backend로 분리 관리합니다.
- 실제 `terraform.tfvars` 같은 민감 파일은 커밋하지 않습니다.
- GitHub Actions와 클러스터 워크로드는 Workload Identity 기반 인증을 우선합니다.
- External Secrets Operator는 GCP Secret Manager 권한을 통해 런타임에 시크릿을 동기화합니다.

즉, 정적 비밀을 레포지토리에 넣지 않고,
실행 시점에 필요한 권한만 부여하는 방식으로 운영합니다.


## 이 레포지토리에서 보여주고 싶은 역량

이 저장소는 다음 역량을 보여주기 위한 결과물입니다.

- 클라우드 인프라를 코드로 설계하고 운영 구조로 정리하는 능력
- Kubernetes 플랫폼 리소스와 컨트롤러 책임을 분리하는 설계 능력
- 환경별 운영 기준과 배포 구조를 일관되게 유지하는 능력
- Secret, Gateway, Certificate, NetworkPolicy 같은 운영 핵심 요소를 통합적으로 다루는 능력
- “리소스를 만든다” 수준이 아니라 “운영 가능한 구조를 만든다”는 관점
