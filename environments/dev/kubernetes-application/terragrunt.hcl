# Dev environment Kubernetes application terragrunt.hcl

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
    cluster_name = "eks-dev"
  }
}

dependency "kubernetes_namespace" {
  config_path = "../kubernetes-namespace"

  # Mock outputs for plan operations
  mock_outputs = {
    name = "sample-app"
  }
}

# Terraform source
terraform {
  source = "../../../modules//kubernetes-application"
}

# Inputs for the Kubernetes application module
inputs = {
  app_name  = "sample-app"
  namespace = dependency.kubernetes_namespace.outputs.name

  labels = {
    environment = "dev"
    managed-by  = "terragrunt"
  }

  replicas = 2

  containers = [
    {
      name  = "sample-app"
      image = "nginx:latest"
      ports = [
        {
          container_port = 80
          name           = "http"
        }
      ]
      env = {
        ENVIRONMENT = "dev"
      }
      resources = {
        limits_cpu      = "500m"
        limits_memory   = "512Mi"
        requests_cpu    = "250m"
        requests_memory = "256Mi"
      }
      liveness_probe = {
        path                  = "/"
        port                  = 80
        initial_delay_seconds = 30
        period_seconds        = 10
      }
      readiness_probe = {
        path                  = "/"
        port                  = 80
        initial_delay_seconds = 5
        period_seconds        = 10
      }
    }
  ]

  create_service = true
  service_type   = "ClusterIP"
  service_ports  = [
    {
      name        = "http"
      port        = 80
      target_port = 80
    }
  ]

  create_ingress = true
  ingress_annotations = {
    "kubernetes.io/ingress.class"                    = "nginx"
    "nginx.ingress.kubernetes.io/ssl-redirect"       = "false"
    "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
  }
  ingress_rules = [
    {
      host         = "sample-app.dev.example.com"
      path         = "/"
      path_type    = "Prefix"
      service_port = 80
    }
  ]
}
