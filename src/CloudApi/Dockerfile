# Estágio de Build (SDK para compilar - Imagem Pesada)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["CloudAPI.csproj", "."]
RUN dotnet restore
COPY . .
# Publica o projeto para a pasta /app/publish
RUN dotnet publish "CloudAPI.csproj" -c Release -o /app/publish --no-self-contained

# Estágio Final (Runtime para execução - Imagem Leve)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
# Copia apenas os binários compilados do estágio anterior
COPY --from=build /app/publish .

# Porta padrão 80 para facilitar a integração com o Load Balancer e API Gateway
ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80

ENTRYPOINT ["dotnet", "CloudAPI.dll"]