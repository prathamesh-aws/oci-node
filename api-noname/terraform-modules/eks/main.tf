terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes",
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm",
      version = "~> 2.13",
    }
  }
}

variable "cluster_name" {
  description = "The name of the EKS cluster to deploy the noname sensor on"
  type        = string
}

variable "noname_kubernetes_namespace" {
  description = "The name of the kubernetes namespace that will be created for the noname sensor"
  type        = string
  default     = "noname-security"
}

variable "helm_folder_path" {
  description = "Path to the folder containing the Helm chart"
  type        = string
  default     = "."
}

resource "kubernetes_namespace" "noname_sensor_namespace" {
  metadata {
    name = var.noname_kubernetes_namespace
  }
}

# Wait 10 seconds before destroying the namespace to let the cleanup job time to finish
resource "time_sleep" "wait_10_seconds_before_destroy" {
  depends_on       = [kubernetes_namespace.noname_sensor_namespace]
  destroy_duration = "10s"
}

# Apply helm chart 
resource "helm_release" "noname_remote_operator" {
  depends_on = [time_sleep.wait_10_seconds_before_destroy]
  wait       = true
  name       = "noname-remote-operator"
  chart      = var.helm_folder_path
  values     = [file("${var.helm_folder_path}/values.yaml")]
  namespace  = var.noname_kubernetes_namespace
}
