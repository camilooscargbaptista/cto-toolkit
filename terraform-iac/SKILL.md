---
name: terraform-iac
description: "**Terraform & Infrastructure as Code**: Helps write, review, and structure Terraform configurations, modules, state management, and IaC best practices. Use whenever the user mentions 'terraform', 'IaC', 'infrastructure as code', '.tf files', 'HCL', 'terraform module', 'terraform state', 'terraform plan', 'terraform apply', 'tfvars', 'remote state', 'terragrunt', 'OpenTofu', 'infrastructure provisioning', or asks about creating/managing cloud resources declaratively, writing reusable infrastructure modules, or managing multi-environment infrastructure."
---

# Terraform & Infrastructure as Code

You are a senior platform engineer helping design, write, and review Terraform configurations. Focus on modularity, security, and maintainability — infrastructure code is as important as application code.

## Project Structure

### Standard Layout

```
infrastructure/
├── modules/                    # Reusable modules
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── database/
│   ├── compute/
│   └── monitoring/
├── environments/               # Environment-specific configs
│   ├── production/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── provider.tf
│   ├── staging/
│   └── dev/
├── global/                     # Shared resources (IAM, DNS, etc.)
│   ├── iam/
│   └── dns/
└── scripts/                    # Helper scripts
```

### File Conventions

| File | Purpose |
|------|---------|
| `main.tf` | Primary resource definitions |
| `variables.tf` | Input variables with descriptions and validation |
| `outputs.tf` | Module outputs |
| `locals.tf` | Local values and computed expressions |
| `provider.tf` | Provider configuration and version constraints |
| `backend.tf` | State backend configuration |
| `data.tf` | Data sources (existing resources, SSM params, etc.) |

## Module Best Practices

- One logical concern per module (networking, database, compute — not everything)
- Never hardcode values — use variables with sensible defaults
- Always include descriptions on variables and outputs
- Add validation blocks for input constraints
- Use `locals` for computed values and repeated expressions
- Pin provider versions in the module
- Include a README with usage examples

For detailed examples of module interfaces, naming conventions, and patterns like conditional resources and for_each, see **[references/module-examples.md](./references/module-examples.md)**.

## State Management

### Remote State Concept

Terraform state is a database of all managed resources. Without remote state, teams overwrite each other's work and lose history. Remote state enables:

- **Team collaboration**: Single source of truth for infrastructure
- **Locking**: Prevents concurrent modifications (DynamoDB, Consul, etc.)
- **Encryption**: Secrets stored encrypted at rest
- **Audit trail**: Version history and backup

### State Best Practices

- Always use remote state with locking (S3 + DynamoDB, GCS, Terraform Cloud)
- Separate state files per environment (never share state between prod and dev)
- State per domain: networking, database, compute in separate states (blast radius containment)
- Never manually edit state files
- Use `terraform state mv` for refactoring, not manual edits
- Enable state encryption at rest and in transit
- Restrict state bucket access to CI/CD and senior engineers only

For state import, move, and recovery operations, see **[references/module-examples.md#state-operations](./references/module-examples.md#state-operations)**.

## Review Checklist

When reviewing Terraform code:

```markdown
- [ ] No hardcoded values (use variables)
- [ ] No secrets in code or tfvars (use SSM/Secrets Manager)
- [ ] Variables have descriptions and validation
- [ ] Outputs documented and marked sensitive where needed
- [ ] Resources tagged consistently
- [ ] IAM follows least privilege (no wildcards)
- [ ] State isolation appropriate (per environment, per domain)
- [ ] Provider versions pinned
- [ ] terraform fmt applied
- [ ] No unnecessary data sources (could be a variable instead)
- [ ] Destruction protection on stateful resources (prevent_destroy)
- [ ] Backup/retention policies on databases and storage
```

## Security & Secrets

Sensitive infrastructure data (database passwords, API keys, IAM credentials) must never be hardcoded or committed to VCS. Always use external secret stores.

Key practices:
- Never hardcode secrets; use AWS Secrets Manager, SSM Parameter Store, or similar
- Mark variables and outputs containing secrets as `sensitive = true`
- Use random_password for auto-generated credentials
- Implement IAM least privilege (specific permissions, no wildcards)
- Enable state encryption with KMS for production

For detailed examples and patterns, see **[references/security-secrets.md](./references/security-secrets.md)**.

## CI/CD Integration

Terraform pipelines automate planning and applying changes, with safeguards for production.

Key pattern:
- Run `terraform plan` on every PR for review
- Run `terraform apply` only on merge to main/protected branches
- Require manual approval before production applies
- Use `-out=tfplan` to save plans and prevent drift between plan & apply
- Validate and format check as automated gatekeepers
- Pin Terraform and provider versions

For complete GitHub Actions workflows, best practices, OIDC setup, and state locking, see **[references/cicd-terraform.md](./references/cicd-terraform.md)**.
