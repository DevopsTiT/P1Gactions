variable "kubeconfig_path" {
  description = "Path to kubeconfig (Minikube writes here by default)"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "kubectl context name for Minikube"
  type        = string
  default     = "minikube"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "app_name" {
  type    = string
  default = "p1gactions"
}

variable "image" {
  description = "Container image (must exist in Minikube when image_pull_policy=Never)"
  type        = string
  default     = "ghcr.io/devopstit/p1gactions:latest"
}

variable "image_pull_policy" {
  type    = string
  default = "Never"
}

variable "replicas" {
  type    = number
  default = 1
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "service_port" {
  type    = number
  default = 80
}

variable "node_port" {
  description = "NodePort for Minikube service access"
  type        = number
  default     = 30080
}
