# Production environment Kubernetes namespace terragrunt.hcl

# Include the root terragrunt.hcl file directly
include {
  path = find_in_parent_folders()
}

# Import environment-specific variables
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

# Define dependencies
dependency "kubernetes_cluster" {
  config_path = "../kubernetes-cluster"

  # Mock outputs for plan operations
  mock_outputs = {
    cluster_name = "eks-prod"
  }
}

# Terraform source
terraform {
  source = "../../../modules//kubernetes-namespace"
}

# Inputs for the Kubernetes namespace module
inputs = {
  namespace_name = "sample-app"

  labels = {
    environment = "prod"
    managed-by  = "terragrunt"
  }

  annotations = {
    description = "Namespace for sample application in production environment"
  }

  create_resource_quota = true
  quota_requests_cpu    = "4"
  quota_requests_memory = "8Gi"
  quota_limits_cpu      = "8"
  quota_limits_memory   = "16Gi"
  quota_pods            = "20"

  create_network_policy       = true
  allowed_ingress_namespaces = ["default", "kube-system", "monitoring", "ingress-nginx"]
}
