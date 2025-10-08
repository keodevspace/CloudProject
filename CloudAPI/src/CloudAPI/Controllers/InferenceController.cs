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