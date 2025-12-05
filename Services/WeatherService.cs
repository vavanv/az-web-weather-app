using ASP_Core.Models;
using ASP_Core.Services.Dtos;

namespace ASP_Core.Services
{
    public class WeatherService : IWeatherService
    {
        private readonly HttpClient _httpClient;

        public WeatherService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            var baseUrl = configuration["WeatherApi:BaseUrl"];
            if (!string.IsNullOrEmpty(baseUrl))
            {
                _httpClient.BaseAddress = new Uri(baseUrl);
            }
        }

        public async Task<List<WeatherForecast>> GetWeatherForecastsAsync()
        {
            var response = await _httpClient.GetFromJsonAsync<List<WeatherForecastDto>>("WeatherForecast");

            if (response == null)
            {
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
    }
}
