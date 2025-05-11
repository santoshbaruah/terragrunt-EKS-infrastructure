# Staging environment VPC terragrunt.hcl

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
  name                 = "staging"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
  availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
  cluster_name         = "eks-staging"

  # Tags
  tags = {
    Environment = "staging"
    ManagedBy   = "Terragrunt"
    Project     = "KubernetesInfrastructure"
  }
}
