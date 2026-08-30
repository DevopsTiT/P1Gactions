# Points at your local Minikube kubeconfig context.
# Prerequisites: `minikube start` and (for this app image) `minikube image load ...`
provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kube_context
}
