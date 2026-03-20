# Cloud Infrastructure Governance & Compliance Automation Platform

A production-grade cloud governance platform built on AWS using 
Terraform, demonstrating automated patch management, vulnerability 
detection, and security remediation across multiple environments.

## Architecture Overview
```
┌─────────────────────────────────────────────────────────┐
│                    AWS Account                          │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ Non-Prod │  │   Prod   │  │    DR    │               │
│  │  VPC     │  │  VPC     │  │  VPC     │               │
│  │ 10.0.0/16│  │ 10.1.0/16│  │ 10.2.0/16│               │
│  └──────────┘  └──────────┘  └──────────┘               │
│                                                         │
│  ┌─────────────────────────────────────────────┐        │
│  │           Patch Management                  │        │
│  │  SSM Patch Manager → Maintenance Windows    │        │
│  │  → Lambda Reporter → S3 Reports → SNS       │        │
│  └─────────────────────────────────────────────┘        │
│                                                         │
│  ┌─────────────────────────────────────────────┐        │
│  │         Vulnerability Remediation           │        │
│  │  Security Hub → EventBridge → Lambda        │        │
│  │  → Auto-Remediate or SNS Escalation         │        │
│  └─────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

## Features

### Infrastructure as Code
- Multi-environment VPC architecture (Non-Prod, Prod, DR)
- Reusable Terraform modules for all components
- Private subnets with SSM VPC endpoints — no SSH required
- All environments managed from a single codebase

### Automated Patch Management
- SSM Patch Manager with custom baselines per environment
- Non-Prod: 3 day approval delay, first Sunday monthly
- Prod/DR: 7 day approval delay for safer rollouts
- Lambda generates compliance reports saved to S3
- EventBridge triggers monthly compliance reporting

### Vulnerability Detection & Auto-Remediation
- AWS Security Hub with AWS Foundational Security Best Practices
- EventBridge watches for HIGH/CRITICAL findings in real time
- Lambda auto-remediates:
  - Public S3 buckets → blocks public access automatically
  - Unrestricted security groups → removes dangerous port rules
  - S3 versioning disabled → enables versioning automatically
- Findings that can't be auto-remediated → SNS escalation alert

### CI/CD Pipeline
- GitHub Actions validates Terraform on every push
- Enforces formatting standards with terraform fmt
- Runs terraform validate and terraform plan automatically
- Prevents broken code from reaching main branch

## Tech Stack

| Category   | Technology                  |
|------------|-----------------------------| 
| Cloud      | AWS                         |
| IaC        | Terraform                   |
| Compute    | EC2, Lambda (Python 3.11)   |
| Security   | Security Hub, SSM, IAM      |
| Networking | VPC, Subnets, VPC Endpoints |
| Storage    | S3                          | 
| Messaging  | SNS, EventBridge            |
| CI/CD      | GitHub Actions              |

## Project Structure
```
cloud-governance-platform/
├── .github/
│   └── workflows/
│       └── terraform-validate.yml   # CI/CD pipeline
├── terraform/
│   ├── modules/
│   │   ├── vpc/                     # VPC, subnets, endpoints
│   │   ├── ec2/                     # EC2, IAM, security groups
│   │   ├── notifications/           # SNS topics
│   │   ├── patch-management/        # SSM patch baselines
│   │   ├── lambda/                  # Compliance reporter
│   │   └── security/                # Vulnerability remediator
│   └── environments/
│       └── non-prod/                # Non-prod environment
├── lambda/
│   ├── patch-compliance-reporter/   # Generates S3 compliance reports
│   └── vulnerability-remediator/    # Auto-remediates security findings
├── docs/
│   └── known-issues.md
├── diagrams/
│   └── screenshots/                 # AWS Console evidence
└── README.md
```

## Environments

| Environment |     CIDR    |   Instances  | Patch Delay |
|-------------|-------------|--------------|-------------|
| Non-Prod    | 10.0.0.0/16 | 2 x t3.micro | 3 days      |
| Prod        | 10.1.0.0/16 | 2 x t3.micro | 7 days      |
| DR          | 10.2.0.0/16 | 2 x t3.micro | 7 days      |

## Key Engineering Decisions

**Private subnets with VPC Endpoints instead of public subnets**
EC2 instances live in private subnets with no internet access.
SSM VPC Interface Endpoints allow Systems Manager access without
exposing instances to the internet — eliminating the need for SSH.

**Modular Terraform design**
All infrastructure is written as reusable modules. A fix or 
improvement in a module automatically applies to all environments
that use it — no code duplication.

**Graduated patch approval delays**
Non-prod gets patches first with a 3 day delay. If no issues,
prod and DR follow with a 7 day delay. This mirrors real enterprise
patching strategies.

**Auto-remediation with escalation fallback**
Lambda attempts auto-remediation for known finding types. Unknown
or complex findings trigger an SNS alert for manual review — 
balancing automation with human oversight.

## Author

**Praneeth Kulkarni**
Systems Administrator transitioning to Cloud Engineering