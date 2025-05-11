# Root terragrunt.hcl file
# This file contains common configurations that will be inherited by all child terragrunt.hcl files

locals {
  # Parse the file path to extract the environment
  # Use a more flexible regex pattern that works with the current directory structure
  env = try(
    regex("environments/([^/]+)", get_original_terragrunt_dir())[0],
    "unknown"
  )

  # Common tags for all resources
  common_tags = {
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Project     = "KubernetesInfrastructure"
  }

  # AWS region - can be overridden in child terragrunt.hcl files
  aws_region = "us-west-2"
}

# Generate provider configurations that will be shared across all modules
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = ${jsonencode(local.common_tags)}
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "eks-${local.env}"
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure root inputs that can be used by all child terragrunt.hcl files
inputs = {
  aws_region = local.aws_region
  tags       = local.common_tags
}

# Terraform version constraint
terraform {
  # Force Terraform to keep trying to acquire a lock for up to 20 minutes if someone else already has the lock
  extra_arguments "retry_lock" {
    commands = [
      "init",
      "apply",
      "refresh",
      "import",
      "plan",
      "destroy"
    ]

    arguments = [
      "-lock-timeout=20m"
    ]
  }
}
