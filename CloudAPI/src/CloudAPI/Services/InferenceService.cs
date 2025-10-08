using Amazon.DynamoDBv2.DataModel;

namespace CloudAPI.Services
    {
    public class InferenceService
        {
        private readonly IDynamoDBContext _dbContext;

        public InferenceService(IDynamoDBContext dbContext) => _dbContext = dbContext;

        public async Task<string> RunInferenceAndLog(string inputData)
            {
            // **SIMULA��O DE CHAMADA A PLATAFORMAS AI**
            var prediction = inputData.Length > 15 ? "RISCO CR�TICO" : "RISCO BAIXO";

            // **LOG DE DADOS NO DYNAMODB**
            var log = new InferenceLog { InputData = inputData, PredictedOutput = prediction };
            await _dbContext.SaveAsync(log);

            return prediction;
            }
        }
    }