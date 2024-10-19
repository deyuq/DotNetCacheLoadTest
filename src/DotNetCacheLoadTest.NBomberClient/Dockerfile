FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
USER $APP_UID
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["DotNetCacheLoadTest.NBomberClient/DotNetCacheLoadTest.NBomberClient.csproj", "DotNetCacheLoadTest.NBomberClient/"]
RUN dotnet restore "DotNetCacheLoadTest.NBomberClient/DotNetCacheLoadTest.NBomberClient.csproj"
COPY . .
WORKDIR "/src/DotNetCacheLoadTest.NBomberClient"
RUN dotnet build "DotNetCacheLoadTest.NBomberClient.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "DotNetCacheLoadTest.NBomberClient.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DotNetCacheLoadTest.NBomberClient.dll"]
