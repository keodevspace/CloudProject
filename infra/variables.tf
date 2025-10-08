variable "aws_region" {
  description = "Regi�o da AWS para deploy."
  type        = string
  default     = "us-east-1" 
}

variable "project_name" {
  description = "cloud_project"
  type        = string
  default     = "cloud_api"
}

# --- Vari�veis para rede (Configure com seus IDs reais) ---
variable "vpc_id" {
  description = "ID da VPC existente para o ECS Fargate"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs das Subnets P�blicas dentro da VPC"
  type        = list(string)
}