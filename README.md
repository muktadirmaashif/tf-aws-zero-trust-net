# AWS Zero Trust VPC+S3 Network

![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-232F3E?logo=amazon-aws)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)
![Security](https://img.shields.io/badge/Security-Trivy%20%7C%20Zero--Trust-orange?logo=owasp)

## 📖 Overview
An enterprise-grade, modular Terraform platform that provisions a fully isolated AWS network topology with zero-trust storage boundaries. Built using advanced HCL patterns (`for_each`, `dynamic`, `conditionals`), it enforces encryption, network isolation, compliance logging, and DevSecOps guardrails out-of-the-box. Designed for multi-environment deployment, peer review workflows, and production resilience.

## 🏗️ Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                          ROOT MODULE                         │
│  (Composition, Remote State, Provider Config, tfvars)        │
└──────────────┬──────────────────────────────┬────────────────┘
               │                              │
    ┌──────────▼──────────┐      ┌────────────▼────────────┐
    │      VPC MODULE     │      │       S3 MODULE         │
    │ • Public/Private RT │      │ • Log Bucket (No Ver.)  │
    │ • Flow Logs (CW)    │      │ • Data Buckets (KMS)    │
    │ • S3 Gateway EP     │───┐  │ • TLS-Only Policies     │
    │ • STS Interface EP  │   └──│ • VPC-Only Bucket Pol.  │
    └─────────────────────┘      └─────────────────────────┘
```

## 📁 Project Structure
```
tf-aws-zero-trust-net/
├── modules/
│   ├── vpc/                 # Network isolation, endpoints, flow logs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── routing.tf
│   │   ├── subnets.tf
│   │   ├── versions.tf
│   │   ├── flowlogs.tf
│   │   └── endpoints.tf
│   └── s3/                  # Hardened storage, policies, encryption
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── policies.tf
│       └── logging.tf
├── root/                    # Composition & environment wiring
│   ├── main.tf              # Remote state + module calls
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── test/                    # Terratest integration suite
│   ├── go.mod
│   ├── vpc_s3_test.go
│   └── Makefile
├── .github/workflows/       # CI/CD pipeline
│   └── zero-trust-pipeline.yml
├── .trivyignore             # Accepted risk documentation
└── README.md
```

## 🚀 Phased Implementation Guide

### Phase 1: VPC Module Core Architecture
**Branch:** `feature/vpc-module-core`
- **What:** Scaffolds VPC, IGW, public/private subnets, and decoupled route tables.
- **Why:** Establishes the foundational network boundary with explicit routing separation.
- **How:** Uses `for_each` over `var.subnet_map` to create stable, index-safe subnets. Associates subnets to route tables using naming convention filters (`contains(split("-", k), "public")`).
- **Key Files:** `modules/vpc/{versions,variables,main,outputs}.tf`

### Phase 2: VPC Security Hardening & PrivateLink
**Branch:** `feature/vpc-security-private-link`
- **What:** Adds VPC Flow Logs, restricts SG egress, provisions S3 Gateway & STS Interface endpoints.
- **Why:** Enables network forensics, eliminates public internet dependency for AWS services, and enforces zero-trust traffic flow.
- **How:** Deploys CloudWatch log groups with 30-day retention. Creates IAM roles with `sts:AssumeRole` for `vpc-flow-logs`. Attaches Gateway endpoints to private route tables and Interface endpoints to private subnets with dedicated SGs. Enables `private_dns_enabled` for transparent SDK resolution.
- **Key Files:** `modules/vpc/flowlogs.tf`, `endpoints.tf`, updated `outputs.tf`

### Phase 3: S3 Module Core & Encryption
**Branch:** `feature/s3-module-encryption`
- **What:** Creates multi-bucket infrastructure with conditional versioning, KMS encryption, and dynamic lifecycle rules.
- **Why:** Supports heterogeneous storage requirements (logs vs. data) while enforcing compliance defaults.
- **How:** Accepts `bucket_config` as `map(object(...))`. Filters creation with `{ for k, v in ... if v.versioning_enabled }`. Uses `dynamic "rule"` for lifecycle configurations, conditionally rendering `noncurrent_version_expiration` only when `days > 0`.
- **Key Files:** `modules/s3/{versions,variables,main,outputs}.tf`

### Phase 4: S3 Zero-Trust Policies & Audit
**Branch:** `feature/s3-zero-trust-policies`
- **What:** Enforces public access block, TLS-only transit, VPC Endpoint-restricted access, and centralized audit logging.
- **Why:** Prevents data exfiltration, meets CIS Benchmark 2.1.3, and ensures complete access traceability.
- **How:** `aws_s3_bucket_public_access_block` sets all 4 flags to `true`. Bucket policies use `jsonencode` with `Deny` on `aws:SecureTransport = false` and `Allow` conditioned on `aws:sourceVpce = var.vpc_endpoint_id`. Logs route to a dedicated bucket via `aws_s3_bucket_logging`.
- **Key Files:** `modules/s3/policies.tf`, `logging.tf`

### Phase 5: Root Composition & Remote State
**Branch:** `feature/root-composition`
- **What:** Wires modules together, configures S3 backend with `use_lockfile = true`, and injects environment variables.
- **Why:** Eliminates DynamoDB dependency for locking while preserving concurrency safety. Centralizes orchestration without embedding logic.
- **How:** `backend "s3"` in `root/main.tf` uses `use_lockfile = true` (TF 1.1+). Passes `module.vpc.s3_endpoint_id` → `module.data_buckets.vpc_endpoint_id` and `module.log_bucket.bucket_ids["access-logs"]` → `module.data_buckets.logging_bucket_name`. Implicit dependency graph ensures correct apply order.
- **Key Files:** `root/{main,variables,outputs,terraform}.tfvars`

## 🔒 Security & Compliance Features
| Control | Implementation | Compliance Mapping |
|---------|----------------|-------------------|
| **Encryption at Rest** | `aws:kms` SSE + `bucket_key_enabled = true` | CIS 2.1.1, NIST 800-53 SC-13 |
| **Encryption in Transit** | Bucket policy `Deny` if `SecureTransport = false` | CIS 2.1.3, PCI-DSS 4.1 |
| **Network Isolation** | S3/STS PrivateLink endpoints, no IGW route on private subnets | Zero-Trust Architecture, CIS 3.1 |
| **Public Access Prevention** | `block_public_acls/policy = true` | CIS 2.1.2, SOC2 CC6.1 |
| **Audit Logging** | VPC Flow Logs + S3 Server Access Logs | ISO 27001 A.12.4, HIPAA 164.312(b) |
| **Least Privilege IAM** | Scoped `logs:*` role for flow logs only | AWS IAM Best Practices |

## 🧪 Testing & CI/CD Pipeline

### Terratest Integration (Phase 6)
- **Branch:** `feature/terratest-e2e-validation`
- **What:** Go-based integration tests provisioning real AWS resources, validating outputs, and cleaning up.
- **Why:** Catches API drift, provider bugs, and policy misconfigurations before merge.
- **How:** `terraform.InitAndApply()` → `terraform.Output()` assertions → `defer terraform.Destroy()`. Runs in parallel (`t.Parallel()`) with 40m timeout.
- **Key File:** `test/vpc_s3_test.go`

### GitHub Actions Pipeline (Phase 7)
- **Branch:** `feature/cicd-automation`
- **What:** Automated validation, security scanning, testing, and gated deployment.
- **Why:** Enforces quality gates, shifts security left, and eliminates manual `apply` risks.
- **How:** 
  1. `validate`: `init` → `fmt -check` → `validate`
  2. `security-scan`: `trivy config --severity CRITICAL,HIGH` (fails pipeline on findings)
  3. `terratest`: OIDC AWS auth → `cd test && make test`
  4. `deploy`: Gated by `environment: production-apply` → manual approval → `apply`
- **Key File:** `.github/workflows/zero-trust-pipeline.yml`

## 🛠️ Usage & Operations

### Prerequisites
- Terraform `>= 1.5.0`
- Go `>= 1.21` (for tests)
- Trivy CLI (for local scanning)
- AWS CLI configured with sufficient permissions (`ec2:*`, `s3:*`, `logs:*`, `iam:*`)

### Bootstrap State
```bash
# Pre-create S3 backend bucket (Terraform cannot create its own backend)
aws s3api create-bucket --bucket org-tf-state-zerotrust --region us-east-1 \
  --create-bucket-configuration LocationConstraint=us-east-1
```

### Local Workflow
```bash
cd root
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Run Tests
```bash
cd test
make test
# Runs fmt, dep tidy, and Terratest suite with deferred destroy
```

### Security Scan
```bash
trivy config --severity CRITICAL,HIGH --format table .
# Fails on unaccepted findings. Use .trivyignore for documented exceptions.
```

## ⚠️ Industry Best Practices & Warnings

| Practice | Rationale |
|----------|-----------|
| **Pre-create S3 State Bucket** | Terraform cannot bootstrap its own backend. CLI/Console creation prevents chicken-egg failures. |
| **Keep `terraform.tfvars` out of VCS** | Production values contain network/CIDR/classification data. Use CI secret injection or environment-specific `.tfvars` loaded at runtime. |
| **`use_lockfile` S3 Permissions** | Requires `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on state key. Ensure CI role lacks restrictive `Deny` conditions. |
| **Never `apply` auto on `main`** | Always gate production applies with GitHub Environment approvals or policy-as-code (OPA/Sentinel). |
| **Test Lifecycle Rules First** | `expiration_days` permanently deletes objects. Validate in staging with non-critical data. |
| **Document `.trivyignore` Entries** | Every suppressed finding must include ticket ID, risk owner, and expiration date. Untracked exceptions break audit compliance. |

## 🐛 Troubleshooting

| Issue | Root Cause | Resolution |
|-------|------------|------------|
| `Error locking state` | `use_lockfile` conditional write failed | Verify S3 bucket allows `PutObject`. Check for stale `.terraform.lock.hcl` in CI cache. |
| `S3 Bucket Policy 403` | VPC Endpoint not fully propagated | Wait 2-3 minutes after `apply`. Interface endpoints require DNS resolution sync. |
| `Trivy fails on `Principal: *`` | False positive due to conditional `aws:sourceVpce` | Add to `.trivyignore` with justification: `SEC-XXXX: Restricted by VPC condition`. |
| `Terratest timeout` | AWS API throttling or large resource creation | Increase `go test -timeout 45m`. Ensure test account isn't rate-limited. |
| `Subnet AZ mismatch` | Region has fewer AZs than subnets defined | `modules/vpc/main.tf` uses `slice()` + `min()` to cap. Adjust `subnet_map` to match available AZs. |

## 📄 License & Contributing
This project follows internal engineering standards and is licensed under MIT. Contributions must include:
- Feature branch workflow (`feature/<name>`)
- `terraform fmt` & `terraform validate` passing
- Terratest coverage for new resources
- Trivy scan results attached to PR

For architectural questions or compliance mapping, open an issue tagged `infra-architecture` or `security-review`.
