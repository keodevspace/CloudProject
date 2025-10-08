# Estágio de Build
FROM [mcr.microsoft.com/dotnet/sdk:8.0](https://mcr.microsoft.com/dotnet/sdk:8.0) AS build
WORKDIR /src
COPY ["CloudAPI.csproj", "."]
RUN dotnet restore
COPY . .
RUN dotnet publish "CloudAPI.csproj" -c Release -o /app/publish --no-self-contained

# Estágio Final (Runtime)
FROM [mcr.microsoft.com/dotnet/aspnet:8.0](https://mcr.microsoft.com/dotnet/aspnet:8.0) AS final
WORKDIR /app
COPY --from=build /app/publish .

# Porta padrão 80: facilita a integração com o Load Balancer e API Gateway
ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80
ENTRYPOINT ["dotnet", "CloudAPI.dll"]