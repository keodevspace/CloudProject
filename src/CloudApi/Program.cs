using CloudAPI.Services;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Extensions.NETCore.Setup; 
using Amazon.Extensions.NETCore;     

var builder = WebApplication.CreateBuilder(args);

// Configuração para AWS SDK e DynamoDB
builder.Services.AddAWSService<IAmazonDynamoDB>();
builder.Services.AddSingleton<IDynamoDBContext, DynamoDBContext>();
builder.Services.AddScoped<InferenceService>();

// Adicionar serviços ao container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configuração do pipeline HTTP
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();



Git failed with a fatal error.
error: open(".vs/CloudProject/FileContentIndex/042ae3af-a5f5-4d87-bf87-63c1452dde9f.vsidx"): Permission denied
fatal: Unable to process path .vs/CloudProject/FileContentIndex/042ae3af-a5f5-4d87-bf87-63c1452dde9f.vsidx 