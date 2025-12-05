using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ASP_Core.Pages
{
    public class UsersModel : PageModel
    {
        private readonly ILogger<UsersModel> _logger;

        public UsersModel(ILogger<UsersModel> logger)
        {
            _logger = logger;
        }

        public List<User> Users { get; set; } = [];

        public void OnGet()
        {
            // Mock user data
            Users =
            [
                new User { Id = 1, Name = "John Doe", Email = "john.doe@example.com", Role = "Admin" },
                new User { Id = 2, Name = "Jane Smith", Email = "jane.smith@example.com", Role = "User" },
                new User { Id = 3, Name = "Bob Johnson", Email = "bob.johnson@example.com", Role = "User" },
                new User { Id = 4, Name = "Alice Brown", Email = "alice.brown@example.com", Role = "Moderator" },
                new User { Id = 5, Name = "Charlie Wilson", Email = "charlie.wilson@example.com", Role = "User" }
            ];
        }
    }

    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
    }
}
