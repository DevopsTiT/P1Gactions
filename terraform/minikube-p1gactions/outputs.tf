output "deployment_name" {
  value = kubernetes_deployment_v1.app.metadata[0].name
}

output "service_name" {
  value = kubernetes_service_v1.app.metadata[0].name
}

output "node_port" {
  value = var.node_port
}

output "smoke_test_hint" {
  value = "minikube service ${var.app_name} --url   OR   kubectl port-forward svc/${var.app_name} 8080:80"
}
