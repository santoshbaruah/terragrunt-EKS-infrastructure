# Production environment Kubernetes application terragrunt.hcl

# Include the environment-specific terragrunt.hcl file
include {
  path = "../terragrunt.hcl"
}

# Define dependencies
dependency "kubernetes_cluster" {
  config_path = "../kubernetes-cluster"

  # Mock outputs for plan operations
  mock_outputs = {
    cluster_name = "eks-prod"
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
    environment = "prod"
    managed-by  = "terragrunt"
  }

  replicas = 5

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
        ENVIRONMENT = "prod"
      }
      resources = {
        limits_cpu      = "2000m"
        limits_memory   = "2Gi"
        requests_cpu    = "1000m"
        requests_memory = "1Gi"
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
    "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
    "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
    "nginx.ingress.kubernetes.io/proxy-body-size"    = "8m"
    "nginx.ingress.kubernetes.io/proxy-read-timeout" = "60"
  }
  ingress_rules = [
    {
      host         = "sample-app.example.com"
      path         = "/"
      path_type    = "Prefix"
      service_port = 80
    }
  ]
  ingress_tls = [
    {
      hosts       = ["sample-app.example.com"]
      secret_name = "sample-app-prod-tls"
    }
  ]
}
