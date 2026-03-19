# Terraform Secrets & Security

## Secrets Management

### NEVER Hardcode Secrets
**Bad:**
```hcl
resource "aws_rds_cluster" "main" {
  master_username = "admin"
  master_password = "MyPassword123!"  # ❌ EXPOSED IN STATE & VCS
}
```

**Good: Use AWS Secrets Manager**
```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix             = "rds-password-"
  recovery_window_in_days = 0  # Immediate deletion in non-prod
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id      = aws_secretsmanager_secret.db_password.id
  secret_string  = random_password.db.result
}

resource "aws_rds_cluster" "main" {
  master_username = "admin"
  master_password = jsondecode(
    aws_secretsmanager_secret_version.db_password.secret_string
  )
}
```

### Using AWS Systems Manager Parameter Store
```hcl
resource "aws_ssm_parameter" "api_key" {
  name      = "/${var.environment}/api-key"
  type      = "SecureString"  # Encrypted at rest
  value     = var.external_api_key
  tier      = "Standard"
  key_id    = aws_kms_key.ssm.id  # Use custom KMS key

  tags = local.common_tags
}

# Retrieve in code (application code, not terraform)
# aws ssm get-parameter --name /prod/api-key --with-decryption
```

### Generate Secrets with random_password
```hcl
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

resource "random_password" "database" {
  length  = 32
  special = true

  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id      = aws_secretsmanager_secret.database.id
  secret_string  = random_password.database.result
}

# Retrieve password for initial setup only
output "database_password" {
  value     = random_password.database.result
  sensitive = true
}
```

### Environment Variables for Secrets
```bash
# Set provider credentials via environment variables (not state)
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"

# Set Terraform variables without storing in VCS
export TF_VAR_database_password="$(aws secretsmanager get-secret-value --secret-id rds-password --query SecretString --output text)"

terraform apply
```

## Sensitive Values in Terraform

### Mark Outputs as Sensitive
```hcl
output "database_password" {
  value       = aws_rds_instance.main.password
  description = "Database password"
  sensitive   = true  # ✓ Won't print in console output
}

output "api_endpoint" {
  value       = aws_api_gateway_stage.main.invoke_url
  description = "API Gateway endpoint"
  sensitive   = false  # Publicly shareable
}
```

### Mark Variables as Sensitive
```hcl
variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL for notifications"
  sensitive   = true  # Won't show in logs or terraform plan output
}
```

### Redacting in Logs
```bash
# Terraform will redact sensitive outputs
terraform plan  # [sensitive] appears in output instead of actual value

# Force output of sensitive values (carefully)
terraform output -json database_password  # Still redacted
echo "SELECT * FROM secrets" | terraform console  # [sensitive] output
```

### State File Protection
```hcl
# Store state in remote backend with encryption
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # Server-side encryption with S3-managed keys
    dynamodb_table = "terraform-locks"
  }
}

# Use KMS for encryption key rotation
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
  }
}
```

## IAM Least Privilege

### Specific Permissions (Not Wildcards)
**Bad:**
```json
{
  "Effect": "Allow",
  "Action": "ec2:*",
  "Resource": "*"
}
```

**Good: Specific Actions & Resources**
```hcl
data "aws_iam_policy_document" "lambda_execution" {
  statement {
    sid    = "ReadDynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [
      aws_dynamodb_table.app.arn,
      "${aws_dynamodb_table.app.arn}/index/*"
    ]
  }

  statement {
    sid    = "WriteCloudWatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.main.function_name}*"
    ]
  }

  statement {
    sid       = "DenyDangerous"
    effect    = "Deny"
    actions   = ["iam:*", "sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_execution.json
}
```

### Assume Role with Conditions
```hcl
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals = {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "lambda" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
```

### Time-Limited Access (STS)
```hcl
variable "temporary_user_duration" {
  type        = number
  description = "Duration in seconds for temporary credentials"
  default     = 3600  # 1 hour
}

# Use in CI/CD with OIDC (see cicd-terraform.md)
# Credentials expire automatically
```

### Resource-Level Tags for Access Control
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Team        = var.team
    CostCenter  = var.cost_center
  }
}

# IAM policy restricted to resources with specific tags
data "aws_iam_policy_document" "tag_based_access" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:StartInstances", "ec2:StopInstances"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Environment"
      values   = [var.environment]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Team"
      values   = [var.team]
    }
  }
}
```
