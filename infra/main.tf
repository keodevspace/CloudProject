terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. DynamoDB: Tabela de Log "aws_dynamodb_table" "inference_log" {
  name = "CloudApi"
  billing_mode = "PAY_PER_REQUEST" # Serverless/Pay-per-use
  hash_key = "Id"
  
  attribute {
    name = "Id"
    type = "S"
  }
}

# 2. ECR: Registro de Imagem Docker
resource "aws_ecr_repository" "api_repo" {
  name = var.project_name
  image_tag_mutability = "MUTABLE"
}

# 3. IAM Roles: Permissões para ECS e DynamoDB
# Role para o ECS poder executar a Task (puxar imagem, enviar logs)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Role para o CÓDIGO C# acessar o DynamoDB
resource "aws_iam_role" "api_task_role" {
  name = "${var.project_name}-api-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_task_dynamodb_policy" {
  role       = aws_iam_role.api_task_role.name
  # Garante permissão total ao DynamoDB, essencial para a função SaveAsync
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" 
}

# 4. ECS Fargate Cluster e Service
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_ecs_task_definition" "api_task" {
  family                   = "${var.project_name}-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.api_task_role.arn # A role com permissão para DynamoDB

  container_definitions = jsonencode([
    {
      name      = var.project_name
      image     = "${aws_ecr_repository.api_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80 # Porta do Dockerfile
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Cria um Security Group básica para ppermitir tráfego na porta 80
resource "aws_security_group" "allow_http" {
  name   = "${var.project_name}-sg"
  vpc_id = var.vpc_id 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "api_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api_task.arn
  desired_count   = 1 
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids 
    security_groups  = [aws_security_group.allow_http.id]
    assign_public_ip = true
  }

  # Garante que as permissões estejam prontas antes do serviço
  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.api_task_dynamodb_policy
  ]
}

# 5. API Gateway: Exposição do Endpoint (Simplificada pelo Fargate)
# Este trecho é complexo e, para simplicidade, a forma mais simples e direta de demonstrar o conceito é focar no Fargate.

# --- Saídas Úteis ---
output "ecr_repository_url" {
  description = "URL do repositório ECR para o push da imagem"
  value       = aws_ecr_repository.api_repo.repository_url
}

output "ecs_service_name" {
  value = aws_ecs_service.api_service.name
}