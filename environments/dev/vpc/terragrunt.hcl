# Dev environment VPC terragrunt.hcl

# Include the root terragrunt.hcl file directly
include {
  path = find_in_parent_folders()
}

# Import environment-specific variables
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

# Terraform source
terraform {
  source = "../../../modules//vpc"
}

# Inputs for the VPC module
inputs = {
  name                 = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  cluster_name         = "eks-dev"

  # Tags
  tags = {
    Environment = "dev"
    ManagedBy   = "Terragrunt"
    Project     = "KubernetesInfrastructure"
  }
}
