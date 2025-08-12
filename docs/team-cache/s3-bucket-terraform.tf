# AWSCostMonitor Team Cache S3 Bucket Setup with Security Best Practices
# Terraform configuration for setting up team cache infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "bucket_name" {
  description = "Name of the S3 bucket for team cache"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be a valid S3 bucket name."
  }
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption instead of SSE-S3"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption (required if enable_kms_encryption is true)"
  type        = string
  default     = ""
}

variable "team_account_ids" {
  description = "List of AWS account IDs that can access the team cache"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Purpose   = "AWSCostMonitor-TeamCache"
    ManagedBy = "Terraform"
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Audit log bucket
resource "aws_s3_bucket" "audit_logs" {
  bucket = "${var.bucket_name}-audit-logs"
  
  tags = merge(var.tags, {
    Purpose = "AWSCostMonitor-AuditLogs"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = "team-cache-access/"
    }

    expiration {
      days = 90
    }
  }
}

# Main team cache bucket
resource "aws_s3_bucket" "team_cache" {
  bucket = var.bucket_name
  
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "team_cache" {
  bucket = aws_s3_bucket.team_cache.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "team_cache" {
  bucket = aws_s3_bucket.team_cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_kms_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_kms_encryption ? var.kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "team_cache" {
  bucket = aws_s3_bucket.team_cache.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "team_cache" {
  bucket = aws_s3_bucket.team_cache.id

  target_bucket = aws_s3_bucket.audit_logs.id
  target_prefix = "team-cache-access/"
}

resource "aws_s3_bucket_lifecycle_configuration" "team_cache" {
  bucket = aws_s3_bucket.team_cache.id

  rule {
    id     = "delete-old-cache-entries"
    status = "Enabled"

    filter {
      prefix = "awscost-team-cache/"
    }

    expiration {
      days = 30
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Bucket policy for cross-account access
resource "aws_s3_bucket_policy" "team_cache" {
  count  = length(var.team_account_ids) > 0 ? 1 : 0
  bucket = aws_s3_bucket.team_cache.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.team_cache.arn,
          "${aws_s3_bucket.team_cache.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "CrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = [for account in var.team_account_ids : "arn:aws:iam::${account}:root"]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:HeadObject"
        ]
        Resource = "${aws_s3_bucket.team_cache.arn}/awscost-team-cache/*"
      },
      {
        Sid    = "CrossAccountList"
        Effect = "Allow"
        Principal = {
          AWS = [for account in var.team_account_ids : "arn:aws:iam::${account}:root"]
        }
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetBucketEncryption"
        ]
        Resource = aws_s3_bucket.team_cache.arn
        Condition = {
          StringLike = {
            "s3:prefix" = "awscost-team-cache/*"
          }
        }
      }
    ]
  })
}

# IAM role for team cache access
resource "aws_iam_role" "team_cache" {
  name = "AWSCostMonitor-TeamCache-${var.bucket_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "team_cache" {
  name = "TeamCacheS3Access"
  role = aws_iam_role.team_cache.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:HeadObject"
        ]
        Resource = "${aws_s3_bucket.team_cache.arn}/awscost-team-cache/*"
      },
      {
        Sid    = "S3List"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetBucketEncryption",
          "s3:HeadBucket"
        ]
        Resource = aws_s3_bucket.team_cache.arn
      }
    ], var.enable_kms_encryption ? [
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ] : [])
  })
}

# Outputs
output "bucket_name" {
  description = "Name of the team cache S3 bucket"
  value       = aws_s3_bucket.team_cache.id
}

output "bucket_arn" {
  description = "ARN of the team cache S3 bucket"
  value       = aws_s3_bucket.team_cache.arn
}

output "audit_log_bucket_name" {
  description = "Name of the audit log bucket"
  value       = aws_s3_bucket.audit_logs.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for team cache access"
  value       = aws_iam_role.team_cache.arn
}

output "bucket_region" {
  description = "Region of the team cache bucket"
  value       = data.aws_region.current.name
}