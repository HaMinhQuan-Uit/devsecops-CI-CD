# DevSecOps CI/CD Pipeline

End-to-end DevSecOps pipeline tích hợp 7 lớp kiểm tra bảo mật tự động,
xây dựng trên GitHub Actions cho ứng dụng Flask + Terraform infrastructure.

## Architecture
## Security Tools

| Layer | Tool | Purpose |
|-------|------|---------|
| SAST | Semgrep | Static code analysis for XSS, SQLi, CMDi |
| Secrets | Gitleaks | Detect API keys, passwords in code |
| Dependencies | pip-audit | CVE scanning in Python packages |
| IaC | Checkov | Terraform misconfiguration detection |
| Container | Trivy | OS & app vulnerability scanning |
| SBOM | Syft | Software Bill of Materials generation |
| Signing | Cosign | Keyless image signing via Sigstore |
| DAST | OWASP ZAP | Dynamic runtime security testing |
| Policy | OPA Conftest | Policy-as-code enforcement |

## Quick Start

### Prerequisites
- Docker
- Python 3.11+
- Git

### Run locally
```bash
# Clone repo
git clone https://github.com/HaMinhQuan-Uit/devsecops-CI-CD.git
cd devsecops-CI-CD

# Run app
cd app && pip install -r requirements.txt
python app.py

# Build container
docker build -t devsecops-demo:test .
docker run -p 5000:5000 devsecops-demo:test

# Test
curl http://localhost:5000/health
```

### Pre-commit hooks
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Pipeline Results

### Clean code (all checks pass)
- SAST: 0 findings
- Secrets: 0 findings
- Dependencies: 0 vulnerable packages
- IaC: 35/35 Checkov checks passed
- Container: 0 CRITICAL CVE (unfixed ignored)
- DAST: ZAP baseline scan passed
- Policy Gate: All policies satisfied
- Image: Signed and pushed to GHCR

### Intentional vulnerabilities (demo detection)
- XSS in /greet endpoint → Semgrep detected
- SQL Injection in /user → Semgrep detected
- Command Injection in /ping → Semgrep detected
- Hardcoded AWS key → Gitleaks detected
- Public S3 bucket → Checkov detected
- Open SSH Security Group → Checkov detected

## Project Structure
## Threat Model

| ID | Threat | Detection Tool | Result |
|----|--------|----------------|--------|
| T1 | Hardcoded secrets | Gitleaks | Blocked |
| T2 | Vulnerable dependency | pip-audit | Blocked |
| T3 | IaC misconfiguration | Checkov | Blocked |
| T4 | Insecure container image | Trivy | Blocked |
| T5 | Runtime vulnerability | OWASP ZAP | Detected |

## Author

Ha Minh Quan - UIT-VNUHCM
Information Security - 4th Year
