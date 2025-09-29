variable "namespace" {
  description = "Namespace where the application will be deployed"
  type        = string
}

variable "release_name" {
  description = "Helm release name for the application"
  type        = string
  default     = "hello-world"
}

variable "replica_count" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = "../../../helm/hello-world"
}

variable "image_repository" {
  description = "Docker image repository for the application"
  type        = string
  default     = "hello-world"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "env" {
  description = "Non-sensitive environment variables (injected as ConfigMap)"
  type        = map(string)
  default = {
    APP_NAME = "hello-world"
    PORT     = "3000"
  }
}

variable "secret_favorite_color" {
  description = "Sensitive environment variable injected as a Secret"
  type        = string
  sensitive   = true
}

variable "resources" {
  description = "Overrides Kubernetes Requests/limits for this environment"
  type = object({
    requests = optional(object({ cpu = string, memory = string }))
    limits   = optional(object({ cpu = string, memory = string }))
  })
  default = null
}

variable "service_type" {
  description = "ServiceType (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "NodePort"
}

variable "service_port" {
  description = "Port exposed by Service within the cluster"
  type        = number
  default     = 3000
}