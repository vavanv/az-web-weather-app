using ASP_Core.Models;

namespace ASP_Core.Services
{
    public interface IWeatherService
    {
        Task<List<WeatherForecast>> GetWeatherForecastsAsync();
    }
}
