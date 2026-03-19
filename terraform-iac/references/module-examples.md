# Terraform Module Examples & Patterns

## Module Interface Example

### variables.tf
```hcl
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create"
  default     = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}
```

### outputs.tf
```hcl
output "instance_ids" {
  value       = aws_instance.main[*].id
  description = "List of instance IDs"
}

output "security_group_id" {
  value       = aws_security_group.main.id
  description = "Security group ID for reference in other modules"
}

output "connection_string" {
  value       = "server=${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}"
  description = "Database connection string"
  sensitive   = true
}
```

## Naming Conventions

### Resources
- **Format**: `{resource_type}_{logical_name}` (e.g., `aws_instance_app`, `aws_security_group_alb`)
- **Use**: Descriptive logical names (avoid generic names like `main`, `instance`, `sg`)
- **Prefix**: Module-level resources with context (e.g., in database module: `aws_db_instance_primary`)

### Variables
- **Format**: `snake_case` (e.g., `instance_count`, `enable_encryption`)
- **Prefix**: With module name for clarity in root module (e.g., `vpc_cidr_block`, `database_engine`)
- **Grouping**: Related variables together in `variables.tf`

### Outputs
- **Format**: `snake_case` (e.g., `instance_ids`, `security_group_id`)
- **Prefix**: With module name when used in root module (e.g., `vpc_id`, `database_endpoint`)
- **Return**: All outputs needed by consumers; export IDs, endpoints, ARNs

### Tags & Locals
```hcl
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "networking"
      CreatedAt   = timestamp()
    }
  )

  resource_prefix = "${var.project}-${var.environment}"
}

# Apply to all resources
tags = local.common_tags
```

## Common Patterns

### Conditional Resources (count)
```hcl
variable "enable_monitoring" {
  type    = bool
  default = true
}

resource "aws_cloudwatch_log_group" "app" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7
}

output "log_group_name" {
  value = var.enable_monitoring ? aws_cloudwatch_log_group.app[0].name : null
}
```

### Dynamic Blocks
```hcl
resource "aws_security_group" "main" {
  name = var.sg_name

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}

# Input:
# ingress_rules = [
#   { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
#   { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
# ]
```

### for_each vs count

**Use count when:**
- Creating a fixed number of identical resources
- Conditional creation (0 or 1)
- Indexing by number is acceptable

```hcl
resource "aws_instance" "servers" {
  count         = var.server_count
  instance_type = "t3.micro"
  # ...
}
```

**Use for_each when:**
- Creating resources from a map or set
- IDs are meaningful (e.g., environment names, availability zones)
- Resource destruction order matters

```hcl
variable "environments" {
  type = map(object({
    instance_type = string
    desired_count = number
  }))
}

resource "aws_autoscaling_group" "by_env" {
  for_each      = var.environments
  name          = "asg-${each.key}"
  min_size      = 1
  max_size      = each.value.desired_count
}

output "asg_arns" {
  value = { for k, v in aws_autoscaling_group.by_env : k => v.arn }
}
```

## State Operations

### Import Existing Resource
```bash
# Import manually created S3 bucket into Terraform state
terraform import aws_s3_bucket.existing my-existing-bucket

# Verify state
terraform state show aws_s3_bucket.existing
```

### Move & Rename
```bash
# Rename resource in state (resource code must also be renamed)
terraform state mv aws_instance.old aws_instance.new

# Move resource between modules
terraform state mv aws_instance.main module.networking.aws_instance.main
```

### Remove from State (not destroy)
```bash
# Remove resource from state without destroying AWS resource
terraform state rm aws_instance.temporary
# Resource still exists in AWS; use when migrating management or decommissioning
```

### List & Show State
```bash
# List all resources in state
terraform state list

# Show specific resource details
terraform state show aws_security_group.main

# Export entire state (caution: contains secrets)
terraform show -json
```

### State Backup & Recovery
```bash
# Terraform auto-backs up state to terraform.tfstate.backup
# Manual backup before sensitive operations
cp terraform.tfstate terraform.tfstate.backup.$(date +%s)

# Recover from backup (dangerous operation)
cp terraform.tfstate.backup terraform.tfstate
terraform refresh
```
