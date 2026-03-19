# Terraform in CI/CD Pipelines

## GitHub Actions Workflow

### Plan on PR, Apply on Merge
```yaml
name: Terraform CI/CD

on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform.yml'
  push:
    branches:
      - main
    paths:
      - 'terraform/**'

env:
  TERRAFORM_VERSION: 1.5.7
  AWS_REGION: us-east-1

jobs:
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    permissions:
      id-token: write
      contents: read
      pull-requests: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/terraform-github-actions
          aws-region: ${{ env.AWS_REGION }}
          role-duration-seconds: 3600

      - name: Terraform Init
        working-directory: ./terraform
        run: terraform init

      - name: Terraform Validate
        working-directory: ./terraform
        run: terraform validate

      - name: Terraform Format Check
        working-directory: ./terraform
        run: terraform fmt -check -recursive

      - name: Terraform Plan
        working-directory: ./terraform
        run: |
          terraform plan \
            -out=tfplan \
            -var-file="environments/${{ github.base_ref }}.tfvars"

      - name: Save Plan Artifact
        uses: actions/upload-artifact@v3
        with:
          name: tfplan-${{ github.event.number }}
          path: terraform/tfplan
          retention-days: 3

      - name: Post Plan to PR
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('terraform/tfplan', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Terraform Plan\n\`\`\`\n${plan.substring(0, 8000)}\n\`\`\``
            });

  apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    needs: [validate]

    permissions:
      id-token: write
      contents: read

    environment: production

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/terraform-github-actions
          aws-region: ${{ env.AWS_REGION }}
          role-duration-seconds: 3600

      - name: Terraform Init
        working-directory: ./terraform
        run: terraform init

      - name: Download Plan Artifact
        uses: actions/download-artifact@v3
        with:
          name: tfplan-${{ github.event.pull_request.number }}
          path: terraform/

      - name: Terraform Apply
        working-directory: ./terraform
        run: |
          terraform apply \
            -auto-approve \
            -input=false \
            tfplan

      - name: Post Apply Status
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `✅ Terraform Apply completed: ${{ job.status }}`
            });

  validate:
    name: Terraform Validate
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/terraform-github-actions
          aws-region: ${{ env.AWS_REGION }}
          role-duration-seconds: 1800

      - name: Terraform Init
        working-directory: ./terraform
        run: terraform init

      - name: Terraform Validate
        working-directory: ./terraform
        run: terraform validate

      - name: Format Check
        working-directory: ./terraform
        run: terraform fmt -check -recursive

      - name: TFLint (optional)
        uses: terraform-linters/setup-tflint@v4
        with:
          tflint_version: latest

      - name: Run TFLint
        working-directory: ./terraform
        run: |
          tflint --init
          tflint --format compact
```

## Pipeline Best Practices

### Manual Approval for Production
```yaml
apply:
  name: Terraform Apply
  runs-on: ubuntu-latest
  needs: [plan, validate]
  if: github.ref == 'refs/heads/main'
  environment:
    name: production  # Requires approval before deploy
  steps:
    # ... apply steps
```

### Use -out=tfplan for Apply
```bash
# Always save plan to file
terraform plan -out=tfplan

# Apply only from saved plan (prevents drift between plan & apply)
terraform apply tfplan

# Never use auto-approve without saved plan
```

### OIDC Authentication (No Long-Lived Credentials)
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT_ID:role/github-actions
    aws-region: us-east-1
    role-duration-seconds: 3600  # Auto-expires in 1 hour
```

Setup in AWS:
```hcl
# Create OIDC provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Create role for GitHub to assume
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals = {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:my-org/my-repo:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

# Attach minimal permissions policy
resource "aws_iam_role_policy_attachment" "github_terraform" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.terraform_permissions.arn
}
```

### Pin Terraform Version
```hcl
# In terraform block
terraform {
  required_version = "~> 1.5.0"  # Allow patch updates only

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

In GitHub Actions:
```yaml
env:
  TERRAFORM_VERSION: 1.5.7  # Pin exact version

steps:
  - uses: hashicorp/setup-terraform@v2
    with:
      terraform_version: ${{ env.TERRAFORM_VERSION }}
```

### State Locking
```hcl
# Backend configuration
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Create DynamoDB table for state locks
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}
```

### Workspace Strategy
```bash
# Use workspaces for environment separation
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Select workspace
terraform workspace select prod

# Apply to current workspace
terraform apply -var-file="environments/prod.tfvars"
```

### Drift Detection (Scheduled)
```yaml
name: Terraform Drift Detection

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  drift-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Refresh
        working-directory: ./terraform
        run: terraform refresh
      - name: Terraform Plan (Drift Check)
        working-directory: ./terraform
        run: terraform plan -detailed-exitcode
```

### Pre-commit Hooks (Local)
```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.81.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
      - id: checkov

# Install: pre-commit install
# Run: pre-commit run --all-files
```
