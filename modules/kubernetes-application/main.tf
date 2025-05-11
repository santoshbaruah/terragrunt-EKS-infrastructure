/**
 * # Kubernetes Application Module
 *
 * This module deploys an application to a Kubernetes cluster.
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

# Deployment resource
resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = merge(
      {
        app = var.app_name
      },
      var.labels
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = merge(
          {
            app = var.app_name
          },
          var.labels
        )
      }

      spec {
        dynamic "container" {
          for_each = var.containers
          content {
            name  = container.value.name
            image = container.value.image

            dynamic "port" {
              for_each = container.value.ports != null ? container.value.ports : []
              content {
                container_port = port.value.container_port
                name           = port.value.name
                protocol       = port.value.protocol
              }
            }

            dynamic "env" {
              for_each = container.value.env != null ? container.value.env : {}
              content {
                name  = env.key
                value = env.value
              }
            }

            dynamic "resources" {
              for_each = container.value.resources != null ? [container.value.resources] : []
              content {
                limits = {
                  cpu    = resources.value.limits_cpu
                  memory = resources.value.limits_memory
                }
                requests = {
                  cpu    = resources.value.requests_cpu
                  memory = resources.value.requests_memory
                }
              }
            }

            dynamic "liveness_probe" {
              for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []
              content {
                http_get {
                  path = liveness_probe.value.path
                  port = liveness_probe.value.port
                }
                initial_delay_seconds = liveness_probe.value.initial_delay_seconds
                period_seconds        = liveness_probe.value.period_seconds
              }
            }

            dynamic "readiness_probe" {
              for_each = container.value.readiness_probe != null ? [container.value.readiness_probe] : []
              content {
                http_get {
                  path = readiness_probe.value.path
                  port = readiness_probe.value.port
                }
                initial_delay_seconds = readiness_probe.value.initial_delay_seconds
                period_seconds        = readiness_probe.value.period_seconds
              }
            }
          }
        }
      }
    }
  }
}

# Service resource
resource "kubernetes_service" "this" {
  count = var.create_service ? 1 : 0

  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = merge(
      {
        app = var.app_name
      },
      var.labels
    )
  }

  spec {
    selector = {
      app = var.app_name
    }

    dynamic "port" {
      for_each = var.service_ports
      content {
        name        = port.value.name
        port        = port.value.port
        target_port = port.value.target_port
        protocol    = port.value.protocol
      }
    }

    type = var.service_type
  }
}

# Ingress resource
resource "kubernetes_ingress_v1" "this" {
  count = var.create_ingress ? 1 : 0

  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = merge(
      {
        app = var.app_name
      },
      var.labels
    )
    annotations = var.ingress_annotations
  }

  spec {
    dynamic "rule" {
      for_each = var.ingress_rules
      content {
        host = rule.value.host
        http {
          path {
            path      = rule.value.path
            path_type = rule.value.path_type

            backend {
              service {
                name = kubernetes_service.this[0].metadata[0].name
                port {
                  number = rule.value.service_port
                }
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = var.ingress_tls
      content {
        hosts       = tls.value.hosts
        secret_name = tls.value.secret_name
      }
    }
  }
}

# Output the deployment name
output "deployment_name" {
  value = kubernetes_deployment.this.metadata[0].name
}

output "service_name" {
  value = var.create_service ? kubernetes_service.this[0].metadata[0].name : null
}

output "ingress_name" {
  value = var.create_ingress ? kubernetes_ingress_v1.this[0].metadata[0].name : null
}
