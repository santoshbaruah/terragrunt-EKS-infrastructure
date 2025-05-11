# Dev environment Kubernetes cluster terragrunt.hcl

# Include the environment-specific terragrunt.hcl file
include {
  path = "../terragrunt.hcl"
}

# Define dependencies
dependency "vpc" {
  config_path = "../vpc"

  # Mock outputs for plan operations
  mock_outputs = {
    subnet_ids         = ["subnet-mock-1", "subnet-mock-2", "subnet-mock-3"]
    security_group_ids = ["sg-mock-1"]
  }
}

# Terraform source
terraform {
  source = "../../../modules//kubernetes-cluster"
}

# Inputs for the Kubernetes cluster module
inputs = {
  cluster_name       = "eks-dev"
  kubernetes_version = "1.32"
  subnet_ids         = dependency.vpc.outputs.subnet_ids
  security_group_ids = dependency.vpc.outputs.security_group_ids

  # Node group configuration
  node_instance_types = ["t3.medium"]
  node_disk_size      = 20
  node_desired_size   = 2
  node_max_size       = 3
  node_min_size       = 1

  # Enable logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Tags
  tags = {
    Environment = "dev"
    ManagedBy   = "Terragrunt"
    Project     = "KubernetesInfrastructure"
  }
}
