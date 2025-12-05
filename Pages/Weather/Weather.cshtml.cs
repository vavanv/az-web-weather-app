using Microsoft.AspNetCore.Mvc.RazorPages;
using ASP_Core.Models;
using ASP_Core.Services;

namespace ASP_Core.Pages.Weather
{
    public class WeatherModel : PageModel
    {
        private readonly IWeatherService _weatherService;

        public WeatherModel(IWeatherService weatherService)
        {
            _weatherService = weatherService;
        }

        public List<WeatherForecast> Forecasts { get; set; } = new();

        public async Task OnGetAsync()
        {
            Forecasts = await _weatherService.GetWeatherForecastsAsync();
        }
    }
}
