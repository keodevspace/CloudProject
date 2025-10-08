using Amazon.DynamoDBv2.DataModel;

namespace CloudAPI.Services
{
    // A tabela DynamoDB será criada via Terraform ou manualmente com este nome
    [DynamoDBTable("InferenceLog")] 
    public class InferenceLog
    {
        [DynamoDBHashKey]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public string? InputData { get; set; }
        public string? PredictedOutput { get; set; }
    }
}