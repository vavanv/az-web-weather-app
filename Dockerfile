# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["ASP_Core.csproj", "./"]
RUN dotnet restore "ASP_Core.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "ASP_Core.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "ASP_Core.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080

# Set environment variable to ensure ASP.NET Core listens on port 8080
ENV ASPNETCORE_URLS=http://+:8080

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ASP_Core.dll"]
