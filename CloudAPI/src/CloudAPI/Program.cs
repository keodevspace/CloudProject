using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Extensions.NETCore.Setup; // Add this using directive
using CloudAPI.Services;

// ... start up ...
var builder = WebApplication.CreateBuilder(args);

// Configuração do AWS e DynamoDB
builder.Services.AddAWSService<IAmazonDynamoDB>();
builder.Services.AddSingleton<IDynamoDBContext, DynamoDBContext>();
builder.Services.AddScoped<InferenceService>();

var app = builder.Build();