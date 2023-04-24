resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name = "nginx"
    labels = {
      App = "nginx"
    }
  }

  spec {
    replicas = var.min_replicas
    selector {
      match_labels = {
        App = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          App = "nginx"
        }
      }
      spec {
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key = "App"
                  operator = "In"
                  values = [ "nginx" ]
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }

        container {
          image = var.nginx_image
          name  = "nginx"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "64Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "32Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name = "nginx"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = var.target_group_port
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx" {
  metadata {
    namespace = kubernetes_namespace.nginx.metadata[0].name
    name = "nginx"
  }

  spec {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment.nginx.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type = "Utilization"
          average_utilization = 80
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}
