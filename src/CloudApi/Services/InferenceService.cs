using Amazon.DynamoDBv2.DataModel;

namespace CloudAPI.Services
    {
    public class InferenceService
        {
        private readonly IDynamoDBContext _dbContext;

        public InferenceService(IDynamoDBContext dbContext) => _dbContext = dbContext;

        public async Task<string> RunInferenceAndLog(string inputData)
            {
            // SIMULAÇÃO DE CHAMADA A PLATAFORMAS AI (Requisito da Vaga)
            var prediction = inputData.Length > 15 ? "RISCO CRÍTICO" : "RISCO BAIXO";

            // LOG DE DADOS NO DYNAMODB (Requisito de Monitoramento)
            var log = new InferenceLog
                {
                InputData = inputData,
                PredictedOutput = prediction
                };

            // O contêiner C# precisa de permissão via IAM Role para executar SaveAsync
            await _dbContext.SaveAsync(log);

            return prediction;
            }
        }
    }