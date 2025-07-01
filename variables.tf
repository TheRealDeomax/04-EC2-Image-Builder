# ============================================================================
# VARIABLES - EC2 Image Builder Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)."
  }
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "dev"
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "web-server"
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "parent_image_arn" {
  description = "ARN of the parent image to use as base for the recipe"
  type        = string
  default     = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/x.x.x"
  
  validation {
    condition = can(regex("^arn:aws:imagebuilder:", var.parent_image_arn))
    error_message = "Parent image ARN must be a valid Image Builder image ARN."
  }
}

variable "instance_types" {
  description = "List of EC2 instance types for Image Builder to use during build process"
  type        = list(string)
  default     = ["t3.medium"]
  
  validation {
    condition = length(var.instance_types) > 0
    error_message = "At least one instance type must be specified."
  }
}

variable "enable_logging" {
  description = "Enable S3 logging for Image Builder"
  type        = bool
  default     = true
}

variable "enable_schedule" {
  description = "Enable scheduled pipeline execution"
  type        = bool
  default     = false
}

variable "schedule_expression" {
  description = "Cron expression for pipeline schedule (when enable_schedule is true)"
  type        = string
  default     = "cron(0 2 * * sun)" # Weekly on Sunday at 2 AM UTC
}