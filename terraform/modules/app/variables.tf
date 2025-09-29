variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
}

variable "release_name" {
  description = "Helm release name"
  type        = string
}

variable "image_repository" {
  description = "Container image repository"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
}

variable "replica_count" {
  description = "Number of replicas for the Kubernetes Deployment"
  type        = number
  default     = 2
}

variable "env" {
  description = "Non-sensitive envs -> .Values.env"
  type        = map(string)
  default     = {}
}

variable "secret_env" {
  description = "Sensitive envs -> .Values.secretEnv"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "chart_path" {
  description = "Path to Helm chart"
  type        = string
}

variable "resources" {
  description = "Kubernetes requests/limits to be used with Helm Chart"
  type = object({
    requests = optional(object({ cpu = string, memory = string }))
    limits   = optional(object({ cpu = string, memory = string }))
  })
  default = {
    requests = { cpu = "50m",  memory = "64Mi"  }
    limits   = { cpu = "200m", memory = "128Mi" }
  }
}

variable "service_type" {
    type = string 
    default = "NodePort" 
    }

variable "service_port" { 
    type = number 
    default = 3000 
    }