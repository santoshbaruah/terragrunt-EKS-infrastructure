# Dev environment Kubernetes namespace terragrunt.hcl

# Include the environment-specific terragrunt.hcl file
include {
  path = "../terragrunt.hcl"
}

# Define dependencies
dependency "kubernetes_cluster" {
  config_path = "../kubernetes-cluster"

  # Mock outputs for plan operations
  mock_outputs = {
    cluster_name = "eks-dev"
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
    environment = "dev"
    managed-by  = "terragrunt"
  }

  annotations = {
    description = "Namespace for sample application in dev environment"
  }

  create_resource_quota = true
  quota_requests_cpu    = "1"
  quota_requests_memory = "2Gi"
  quota_limits_cpu      = "2"
  quota_limits_memory   = "4Gi"
  quota_pods            = "10"

  create_network_policy       = true
  allowed_ingress_namespaces = ["default", "kube-system"]
}
