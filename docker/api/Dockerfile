FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5000

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY ["GoUrlsApi/GoUrlsApi.csproj", "GoUrlsApi/"]
RUN dotnet restore "GoUrlsApi/GoUrlsApi.csproj"

# Copy source code
COPY GoUrlsApi/ GoUrlsApi/
WORKDIR "/src/GoUrlsApi"

# Build the application
RUN dotnet build "GoUrlsApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "GoUrlsApi.csproj" -c Release -o /app/publish

# Install EF Core tools in the SDK stage
RUN dotnet tool install --global dotnet-ef --version 9.0.0
ENV PATH="$PATH:/root/.dotnet/tools"

# Generate EF migration bundle for production deployment
RUN dotnet ef migrations bundle --configuration Release --output /app/publish/migrate

FROM base AS final
WORKDIR /app

# Install necessary packages for health checks and PostgreSQL client
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy published application
COPY --from=publish /app/publish .

# Copy appsettings for production
COPY docker/api/appsettings.Production.json ./appsettings.Production.json

# Create entrypoint script
COPY docker/api/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]