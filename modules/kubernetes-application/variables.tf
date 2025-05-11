variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy the application to"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 1
}

variable "containers" {
  description = "List of containers to deploy"
  type = list(object({
    name  = string
    image = string
    ports = optional(list(object({
      container_port = number
      name           = string
      protocol       = optional(string, "TCP")
    })))
    env = optional(map(string))
    resources = optional(object({
      limits_cpu      = string
      limits_memory   = string
      requests_cpu    = string
      requests_memory = string
    }))
    liveness_probe = optional(object({
      path                  = string
      port                  = number
      initial_delay_seconds = number
      period_seconds        = number
    }))
    readiness_probe = optional(object({
      path                  = string
      port                  = number
      initial_delay_seconds = number
      period_seconds        = number
    }))
  }))
}

variable "create_service" {
  description = "Whether to create a service for the application"
  type        = bool
  default     = true
}

variable "service_type" {
  description = "Type of Kubernetes service to create"
  type        = string
  default     = "ClusterIP"
}

variable "service_ports" {
  description = "Ports to expose on the service"
  type = list(object({
    name        = string
    port        = number
    target_port = number
    protocol    = optional(string, "TCP")
  }))
  default = []
}

variable "create_ingress" {
  description = "Whether to create an ingress for the application"
  type        = bool
  default     = false
}

variable "ingress_annotations" {
  description = "Annotations to apply to the ingress"
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "Rules for the ingress"
  type = list(object({
    host         = string
    path         = string
    path_type    = string
    service_port = number
  }))
  default = []
}

variable "ingress_tls" {
  description = "TLS configuration for the ingress"
  type = list(object({
    hosts       = list(string)
    secret_name = string
  }))
  default = []
}
