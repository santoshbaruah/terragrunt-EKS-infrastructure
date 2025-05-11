variable "namespace_name" {
  description = "Name of the Kubernetes namespace"
  type        = string
}

variable "labels" {
  description = "Labels to apply to the namespace"
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Annotations to apply to the namespace"
  type        = map(string)
  default     = {}
}

variable "create_resource_quota" {
  description = "Whether to create a resource quota for the namespace"
  type        = bool
  default     = false
}

variable "quota_requests_cpu" {
  description = "CPU request quota for the namespace"
  type        = string
  default     = "2"
}

variable "quota_requests_memory" {
  description = "Memory request quota for the namespace"
  type        = string
  default     = "4Gi"
}

variable "quota_limits_cpu" {
  description = "CPU limit quota for the namespace"
  type        = string
  default     = "4"
}

variable "quota_limits_memory" {
  description = "Memory limit quota for the namespace"
  type        = string
  default     = "8Gi"
}

variable "quota_pods" {
  description = "Pod quota for the namespace"
  type        = string
  default     = "20"
}

variable "create_network_policy" {
  description = "Whether to create a network policy for the namespace"
  type        = bool
  default     = false
}

variable "allowed_ingress_namespaces" {
  description = "List of namespaces allowed to access this namespace"
  type        = list(string)
  default     = ["default"]
}
