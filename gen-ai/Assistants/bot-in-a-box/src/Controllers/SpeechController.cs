// Sample code from: https://github.com/microsoft/BotFramework-WebChat

using System;
using System.Security.Cryptography;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Models;
using Services;

namespace TokenSampleApi.Controllers
{
    [ApiController]
    public class SpeechController : ControllerBase
    {
        private readonly SpeechService _speechService;

        private readonly string _speechRegion;
        private readonly string _speechSecret;

        public SpeechController(IConfiguration configuration, SpeechService speechService = null)
        {
            _speechService = speechService;
            _speechRegion = configuration["SPEECH_REGION"];
            _speechSecret = configuration["SPEECH_API_KEY"];
        }

        // Endpoint for generating a Direct Line token bound to a random user ID
        [HttpGet]
        [Route("/api/speech/token")]
        public async Task<IActionResult> Get()
        {
            // Generate a random user ID to use for Speech token
            SpeechTokenDetails speechTokenDetails;
            try
            {
                speechTokenDetails = await _speechService.GetTokenAsync();
            }
            catch (InvalidOperationException invalidOpException)
            {
                return BadRequest(new { message = invalidOpException.Message });
            }

            return this.Ok(new { token = speechTokenDetails.Token, region = _speechRegion });
        }
    }
}