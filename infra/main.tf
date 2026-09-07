terraform {
  required_version = ">= 1.5.0"
}

variable "environment" {
  description = "Nombre del ambiente de despliegue"
  type        = string
  default     = "staging"
}

resource "terraform_data" "deploy_frontend" {
  input = var.environment

  provisioner "local-exec" {
    command = "mkdir -p ../staging && cp -r ../frontend/dist/frontend/browser/. ../staging/"
  }
}

output "deployment_path" {
  description = "Ruta donde se copió el build del frontend"
  value       = "../staging/"
}
