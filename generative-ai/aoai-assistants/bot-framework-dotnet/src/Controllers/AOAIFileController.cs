// Sample code from: https://github.com/microsoft/BotFramework-WebChat

using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Models;
using Services;

namespace TokenSampleApi.Controllers
{
    [ApiController]
    public class AOAIFileController : ControllerBase
    {
        private readonly AOAIClient _aoaiClient;


        public AOAIFileController(IConfiguration configuration, AOAIClient aoaiClient = null)
        {
            _aoaiClient = aoaiClient;
        }

        // Endpoint for generating a Direct Line token bound to a random user ID
        [HttpGet]
        [Route("/openai/files/{fileId}/content")]
        public async Task<IActionResult> Get(string fileId)
        {
            try
            {
                var fileResponse = await _aoaiClient.GetFile(fileId);
                return Ok(fileResponse.Content.ReadAsStream());
            }
            catch (InvalidOperationException invalidOpException)
            {
                return BadRequest(new { message = invalidOpException.Message });
            }

        }
    }
}