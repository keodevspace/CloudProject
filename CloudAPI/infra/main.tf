terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" { region = var.aws_region }

# --- ECR: Registro de Imagem ---
resource "aws_ecr_repository" "api_repo" { name = var.project_name }

# --- DYNAMODB: Tabela de Log (Serverless/Pay-per-use) ---
resource "aws_dynamodb_table" "inference_log" {
  name           = "LenovoInferenceLog"
  billing_mode   = "PAY_PER_REQUEST" 
  hash_key       = "Id"
  attribute { name = "Id", type = "S" }
}

# --- VPC (Rede) ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_nat_gateway = false
}

# --- API GATEWAY SERVERLESS (Integração com Load Balancer) ---
resource "aws_lb" "api_lb" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.allow_http.id] 
}
# ... (Código para API Gateway, Rotas e Integração) ...

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default_stage.invoke_url
}