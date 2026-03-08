# Techbleat DevOps - Infrastructure as Code

Automation for the **Techbleat Superstore** deployment per [Capstone Project 1](https://github.com/techbleat/fruits-veg_market/tree/mini-project) – Techbleat DevOps/SRE Master Class [2025/26].

## Assignment Alignment

| Requirement | Status |
|-------------|--------|
| **Terraform** for Infrastructure setup | ✅ EC2 + Security Group + RDS |
| **Jenkins** for Infrastructure and Application Deployments | ✅ Terraform stages + optional Deploy Application stage |
| Port 22 (SSH), 80 (HTTP), 443 (HTTPS) open | ✅ Security group |
| Port 8000 **NOT** public | ✅ Not in security group |
| Nginx reverse proxy: `/` → frontend, `/api/*` → FastAPI | ✅ `nginx/techbleat.conf` |
| `upstream` blocks, `proxy_pass`, X-Forwarded-* headers | ✅ Nginx config |
| Deployment layout: `/usr/share/nginx/html`, `/etc/nginx/conf.d`, `/home/ec2-user/app` | ✅ Inline in Jenkinsfile |
| FastAPI as systemd service | ✅ `backend/fastapi.service` |
| PostgreSQL (Cloud PaaS) | ✅ RDS in Terraform; EC2 connects via security group |
| **HTTPS (Let's Encrypt)** | ✅ Certbot in Jenkins when DOMAIN_NAME + CERTBOT_EMAIL set |

## Deployment File Layout (VM)

Per assignment:

| Path | Purpose |
|------|---------|
| `/usr/share/nginx/html/` | Static frontend |
| `/etc/nginx/conf.d/` | Nginx configs |
| `/home/ec2-user/app/` | FastAPI backend |

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform installed
- SSH key pair in AWS (default: `MasterClass2025`)
- RDS is created by Terraform (default password: Techbleat2026!)

**Jenkins** – Run locally (`brew install jenkins-lts`) or on a separate EC2. Configure pipeline from SCM.

## Project Structure

```
techbleat-devops/
├── terraform/          # Infrastructure as Code
│   ├── main.tf         # EC2 + Security Group + RDS
│   ├── variables.tf
│   └── outputs.tf
├── nginx/              # Nginx config for deployment
│   └── techbleat.conf
├── backend/            # Backend deployment configs
│   ├── requirements.txt
│   ├── fastapi.service
│   └── README.md
├── Jenkinsfile         # CI/CD pipeline (all logic inline - no external scripts)
└── README.md
```

## Quick Start (Terraform)

```bash
cd techbleat-devops/terraform
terraform init
terraform plan
terraform apply
```

## Application Deployment (Jenkins)

All deployment logic is **inline in the Jenkinsfile** – no external scripts. Use **Pipeline script from SCM**:

1. New Item → Pipeline → OK
2. Pipeline → Definition: **Pipeline script from SCM**
3. SCM: Git, Repository URL: `https://github.com/techbleat/fruits-veg_market`
4. Branch: `mini-project` (or your branch)
5. Script Path: `techbleat-devops/Jenkinsfile`
6. Add credential: **SSH Username with private key**, ID: `techbleat-ec2-key` (for app deployment)
7. Run with `DEPLOY_APP=true`, `DOMAIN_NAME` (e.g. `market.techbleat-stores.co.uk`), and `CERTBOT_EMAIL` – full deploy + HTTPS in one run

**Fully automated:** DATABASE_URL from Terraform, Certbot for HTTPS. No manual steps.

**DNS (fully automated):** Set `domain_name = "market.techbleat-stores.co.uk"` in `terraform.tfvars`. Terraform creates the Route53 hosted zone + A record. One-time: set the 4 nameservers (from `terraform output route53_nameservers`) at your domain registrar. If domain is already in Route53, set `route53_zone_id` instead and leave zone creation to existing.

## Customize

Edit `terraform/variables.tf` to change:
- `region` - AWS region (default: eu-west-1)
- `instance_type` - EC2 size (default: t2.micro)
- `key_name` - Your SSH key pair name
- `db_username`, `db_password`, `db_name` - RDS credentials

## Security

- Port 8000 is **NOT** in the security group (FastAPI internal only)
- Ports 22, 80, 443 are open as required by the project
- No database credentials in frontend

---

## Assignment Deliverables

### Port Usage Explanation

| Port | Purpose | Public? |
|------|---------|---------|
| **22** | SSH access for administration | Yes |
| **80** | HTTP – Let's Encrypt validation (Certbot) | Yes |
| **443** | HTTPS – public traffic (Nginx) | Yes |
| **8000** | FastAPI backend – internal only, accessed via Nginx | **No** |
| **5432** | PostgreSQL – RDS in VPC, EC2 connects outbound | No (cloud → VM only) |

Port 8000 is not in the security group. FastAPI listens on localhost:8000; only Nginx (on 80/443) can reach it.

### Request Flow Diagram

```
Browser
   │ HTTPS :443
   ▼
Nginx (Reverse Proxy)  ← EC2 VM
   │
   ├── /         → /usr/share/nginx/html (static frontend)
   └── /api/*    → proxy_pass http://127.0.0.1:8000 (FastAPI)
                        │
                        └── PostgreSQL (RDS, private subnet)
```

### Nginx Config

See `nginx/techbleat.conf` – upstream block, proxy_pass, X-Forwarded-* headers.

### PostgreSQL Connection

- **Format:** `postgresql+psycopg://user:password@host:5432/dbname?sslmode=require`
- **RDS endpoint:** From `terraform output rds_endpoint` or `database_url`
- **SSL:** Required (`sslmode=require`) for RDS
- **Injection:** DATABASE_URL is set in `/home/ec2-user/app/.env` by Jenkins from Terraform output
