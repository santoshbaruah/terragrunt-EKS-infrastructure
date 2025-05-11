/**
 * # Kubernetes Namespace Module
 *
 * This module creates a Kubernetes namespace with the specified configuration.
 */

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
  required_version = ">= 1.7.0"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace_name

    labels = merge(
      {
        name = var.namespace_name
      },
      var.labels
    )

    annotations = var.annotations
  }
}

# Resource quota for the namespace
resource "kubernetes_resource_quota" "this" {
  count = var.create_resource_quota ? 1 : 0

  metadata {
    name      = "${var.namespace_name}-quota"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.quota_requests_cpu
      "requests.memory" = var.quota_requests_memory
      "limits.cpu"      = var.quota_limits_cpu
      "limits.memory"   = var.quota_limits_memory
      "pods"            = var.quota_pods
    }
  }
}

# Network policy for the namespace
resource "kubernetes_network_policy" "this" {
  count = var.create_network_policy ? 1 : 0

  metadata {
    name      = "${var.namespace_name}-network-policy"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {}
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.allowed_ingress_namespaces[0]
          }
        }
      }

      dynamic "from" {
        for_each = slice(var.allowed_ingress_namespaces, 1, length(var.allowed_ingress_namespaces))
        content {
          namespace_selector {
            match_labels = {
              name = from.value
            }
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

# Output the namespace name
output "name" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "id" {
  value = kubernetes_namespace.this.id
}
