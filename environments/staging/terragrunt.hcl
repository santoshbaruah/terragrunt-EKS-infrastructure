# Staging environment terragrunt.hcl
# This file contains configurations specific to the staging environment

# Include the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# Set environment-specific variables
locals {
  environment = "staging"
  aws_region  = "us-west-2"

  # VPC configuration
  vpc_cidr     = "10.1.0.0/16"
  subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]

  # EKS configuration
  cluster_name       = "eks-${local.environment}"
  kubernetes_version = "1.32"

  # Node group configuration
  node_instance_types = ["t3.large"]
  node_disk_size      = 30
  node_desired_size   = 2
  node_max_size       = 4
  node_min_size       = 2
}

# Override the AWS region for this environment
inputs = {
  aws_region        = local.aws_region
  environment       = local.environment
  vpc_cidr          = local.vpc_cidr
  subnet_cidrs      = local.subnet_cidrs
  cluster_name      = local.cluster_name
  kubernetes_version = local.kubernetes_version
  node_instance_types = local.node_instance_types
  node_disk_size    = local.node_disk_size
  node_desired_size = local.node_desired_size
  node_max_size     = local.node_max_size
  node_min_size     = local.node_min_size
}
