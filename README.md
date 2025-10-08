# Guia Completo para Software Development Junior - Cloud

Este guia abrange os **conceitos teóricos obrigatórios**, com exemplos práticos imediatos, seguido pelo **Projeto Prático Completo** que simula as responsabilidades da vaga (**C# .NET, DynamoDB, Docker, Terraform e AWS Serverless**).

---

## 1. Conteúdo Chave para os Exemplos Práticos

| Conceito | Explicação Breve e Clara | Exemplo Prático (Foco em C# .NET e AWS) |
| :--- | :--- | :--- |
| **Cloud-Native** | Abordagem para construir aplicações que tiram máximo proveito dos serviços de nuvem (escalabilidade, resiliência). Envolve microsserviços e contêineres. | O projeto C# .NET é um **Microsserviço** que roda em um **Contêiner Docker** no **AWS Fargate (Serverless)**. |
| **Serverless** | O provedor de nuvem (AWS) gerencia totalmente a infraestrutura. Você se preocupa apenas com o código e a configuração, não com servidores. | **Amazon DynamoDB** e **AWS Fargate** são serverless. O **API Gateway** é a porta de entrada serverless. |
| **Docker e Contêineres** | Empacota o código C# e todas as dependências em uma unidade isolada. Garante que o ambiente de desenvolvimento seja idêntico ao de produção. | **Dockerfile (Multi-Stage)**: O estágio `build` compila, e o estágio `final` usa apenas o runtime (menor e mais seguro). |
| **IaC (Infrastructure-as-Code)** | Gerenciar e provisionar a infraestrutura (rede, ECR, Fargate, DB) por meio de arquivos de código (**Terraform**). | O código HCL define que a AWS deve criar um `aws_ecr_repository` e um `aws_ecs_service`. |
| **CI/CD** | **CI (Integração Contínua)**: Builds e testes automáticos. **CD (Entrega Contínua)**: Implantação automatizada na nuvem. | Fluxo: 1. Commit C# → 2. Build Docker e Push ECR (**CI**) → 3. Atualização Serviço ECS Fargate via AWS CLI (**CD**). |
| **AI/ML Workflows & Endpoints** | Criar APIs que interagem com plataformas de IA/ML para obter e registrar previsões (**Inferência**). | Uso do `AWSSDK.DynamoDBv2` no `InferenceService` para **salvar logs de requisição e resultado**. |

---

## 2. Projeto Prático Completo: API de Inferência Serverless

Este projeto simula todas as atividades acima descritas.

### A. Estrutura do Projeto

```text
CloudProject/
├── src/
│   ├── CloudAPI/
│   │   ├── Controllers/
│   │   │   └── InferenceController.cs  # O Endpoint de Inferência
│   │   ├── Services/
│   │   │   └── InferenceService.cs     # Lógica de Log e Simulação de AI
│   │   ├── CloudAPI.csproj             # O projeto C# .NET
│   │   └── Dockerfile                  # Contêinerização
├── infra/
│   ├── main.tf                         # Infraestrutura Principal
│   ├── variables.tf                    # Variáveis de Configuração
│   └── terraform.tfvars                # Valores Específicos
````

### B. Desenvolvimento da Aplicação (C\# .NET e DynamoDB)

#### 1\. Comandos CLI Iniciais:

*(No terminal, dentro da pasta `CloudProject-Lenovo/src`)*

```bash
dotnet new webapi -n CloudAPI
cd CloudAPI
dotnet add package AWSSDK.DynamoDBv2
dotnet add package Amazon.Extensions.NETCore.Setup
```

#### 2\. Modelo de Dados (`src/CloudAPI/Services/InferenceLog.cs`):

```csharp
using Amazon.DynamoDBv2.DataModel;

namespace CloudAPI.Services
{
    // A tabela DynamoDB será criada via Terraform ou manualmente com este nome
    [DynamoDBTable("LenovoInferenceLog")] 
    public class InferenceLog
    {
        [DynamoDBHashKey]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public string InputData { get; set; }
        public string PredictedOutput { get; set; }
    }
}
```

#### 3\. Serviço de Lógica (`src/CloudAPI/Services/InferenceService.cs`):

```csharp
using Amazon.DynamoDBv2.DataModel;

namespace CloudAPI.Services
{
    public class InferenceService
    {
        private readonly IDynamoDBContext _dbContext;

        public InferenceService(IDynamoDBContext dbContext) => _dbContext = dbContext;

        public async Task<string> RunInferenceAndLog(string inputData)
        {
            // **SIMULAÇÃO DE CHAMADA A PLATAFORMAS AI**
            var prediction = inputData.Length > 15 ? "RISCO CRÍTICO" : "RISCO BAIXO";

            // **LOG DE DADOS NO DYNAMODB**
            var log = new InferenceLog { InputData = inputData, PredictedOutput = prediction };
            await _dbContext.SaveAsync(log); 

            return prediction;
        }
    }
}
```

#### 4\. Endpoint C\# (`src/CloudAPI/Controllers/InferenceController.cs`):

```csharp
using CloudAPI.Services;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("[controller]")]
public class InferenceController : ControllerBase
{
    private readonly InferenceService _inferenceService;

    public InferenceController(InferenceService inferenceService) => _inferenceService = inferenceService;

    // Endpoint exposto para AI/ML workflows
    [HttpPost("run")] 
    public async Task<IActionResult> RunInference([FromBody] string inputData)
    {
        var result = await _inferenceService.RunInferenceAndLog(inputData);
        return Ok(new { Input = inputData, Prediction = result, Status = "Logged and Inferred" });
    }
}
```

#### 5\. Configuração do Início (`src/CloudAPI/Program.cs`):

```csharp
// ... start up ...
var builder = WebApplication.CreateBuilder(args);

// Adicionar a configuração do AWS e DynamoDB
builder.Services.AddAWSService<Amazon.DynamoDBv2.IAmazonDynamoDB>();
builder.Services.AddSingleton<IDynamoDBContext, DynamoDBContext>();
builder.Services.AddScoped<InferenceService>();

// ... resto dos serviços ...
var app = builder.Build();
//
```

### C. Contêinerização (Docker)

**Arquivo**: `src/CloudAPI/Dockerfile`

```dockerfile
# Estágio de Build
FROM [mcr.microsoft.com/dotnet/sdk:8.0](https://mcr.microsoft.com/dotnet/sdk:8.0) AS build
WORKDIR /src
COPY ["CloudAPI.csproj", "."]
RUN dotnet restore
COPY . .
RUN dotnet publish "CloudAPI.csproj" -c Release -o /app/publish --no-self-contained

# Estágio Final (Runtime)
FROM [mcr.microsoft.com/dotnet/aspnet:8.0](https://mcr.microsoft.com/dotnet/aspnet:8.0) AS final
WORKDIR /app
COPY --from=build /app/publish .

# Porta padrão 80 para facilitar a integração com o Load Balancer e API Gateway
ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80
ENTRYPOINT ["dotnet", "CloudAPI.dll"]
```

### D. Infraestrutura como Código (Terraform)

#### 1\. Arquivo: `infra/main.tf` (Exemplo Parcial)

```terraform
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
```

### E. Pipeline de Deployment (O Workflow Final)

#### 1\. Setup Inicial: (no terminal, dentro da pasta `infra`)

```bash
# Baixa os módulos e provedores
terraform init 

# Aplica as variáveis 
terraform apply --auto-approve 

# Saída: Anote o ecr_repository_url e a api_gateway_url.
```

#### 2\. Build e Push do Docker: (no terminal, dentro da pasta `src/CloudAPI`)

```bash
# Constrói a imagem
docker build -t cloudapi-image . 

# Autentica e Tagueia a imagem para o ECR (substitua <REGION> e <ECR_URI>)
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ECR_URI>
docker tag cloudapi-image:latest <ECR_URI>:latest

# Envia a imagem
docker push <ECR_URI>:latest 
```

#### 3\. Acionamento do Deployment (CD): (no terminal)

```bash
# Força o ECS Service a puxar a nova imagem (substitua <PROJECT_NAME> e <REGION>)
aws ecs update-service \
    --cluster <PROJECT_NAME>-cluster \
    --service <PROJECT_NAME>-service \
    --force-new-deployment \
    --region <REGION>
```

#### 4\. Teste e Monitoramento:

  * **Teste (Via API Gateway Serverless)**: Use a `api_gateway_url` para testar o endpoint (ex: `https://<API_GATEWAY_ID>.execute-api.<REGION>.amazonaws.com/inference/run`).
  * **Monitoramento**: Verifique o **CloudWatch** para logs e o **DynamoDB Console** para confirmar que os dados de log (`InferenceLog`) foram salvos.

<!-- end list -->

```
```