output "release_name" {
  description = "Helm release name"
  value       = helm_release.app.name
}

output "namespace" {
  description = "Namespace where the chart was deployed"
  value       = helm_release.app.namespace
}

output "status" {
  description = "Helm release status"
  value       = helm_release.app.status
}

output "app_service_name" {
  description = "Kubernetes Service name created by the chart"
  value       = "hello-world"
}