using ASP_Core.Models;
using ASP_Core.Services.Dtos;

namespace ASP_Core.Services
{
    public class WeatherService : IWeatherService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<WeatherService> _logger;

        public WeatherService(HttpClient httpClient, ILogger<WeatherService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
        }

        public async Task<List<WeatherForecast>> GetWeatherForecastsAsync()
        {
            try
            {
                var response = await _httpClient.GetFromJsonAsync<List<WeatherForecastDto>>("WeatherForecast");

                if (response == null)
                {
                    _logger.LogWarning("Weather API returned null response");
                    return new List<WeatherForecast>();
                }

                return response.Where(dto => dto.Date != null).Select(dto => new WeatherForecast
                {
                    Date = DateOnly.Parse(dto.Date!),
                    TemperatureC = dto.TemperatureC,
                    Summary = dto.Summary,
                    // TemperatureF is computed
                }).ToList();
            }
            catch (TaskCanceledException ex) when (ex.InnerException is TimeoutException)
            {
                _logger.LogError(ex, "Request to Weather API timed out after {Timeout} seconds", _httpClient.Timeout.TotalSeconds);
                throw new HttpRequestException($"Weather API request timed out after {_httpClient.Timeout.TotalSeconds} seconds. Please check if the API is accessible.", ex);
            }
            catch (TaskCanceledException ex)
            {
                _logger.LogError(ex, "Request to Weather API was cancelled");
                throw new HttpRequestException("Weather API request was cancelled", ex);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "HTTP request to Weather API failed");
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error calling Weather API");
                throw;
            }
        }
    }
}
