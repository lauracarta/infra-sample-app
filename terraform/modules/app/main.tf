resource "helm_release" "app" {
  name             = "${var.release_name}-${var.namespace}"
  namespace        = var.namespace
  chart            = var.chart_path
  create_namespace = true

  atomic          = true # Automatic rollback in case of failures
  cleanup_on_fail = true # Delete resources if Helm can't install
  wait            = true # Block release until all resources are ready
  timeout         = 300  # Max seconds to wait for readiness

  values = [
    yamlencode({
      replicaCount = var.replica_count
      image = {
        repository = var.image_repository
        tag        = var.image_tag
        pullPolicy = "IfNotPresent"
      }
      env       = var.env               # ConfigMap
      secretEnv = var.secret_env        # Secret
      resources = var.resources
      service = {
        type = var.service_type
        port = var.service_port
    }
    })
  ]
}