FROM microsoft/dotnet:2.1-sdk AS installer-env

WORKDIR /app

# Copy everything, test and build
COPY . ./

#Pull in a connection string from the docker build command
#ARG CONNSTR

#Pre-authenticated url for private nuget feed
#ARG AUTHENTICATED_PRIVATE_NUGET_URL

#ENV databaseConfig__ConnectionString=${CONNSTR}

# Restore all the packages from the various sources
RUN dotnet restore -s https://api.nuget.org/v3/index.json #-s ${AUTHENTICATED_PRIVATE_NUGET_URL}

# Find all test projects and run tests
RUN find . -type f -name nunittest.csproj -print0 | xargs -0 -n1 dotnet test

# just to be sure
RUN dotnet build

COPY . /src/dotnet-function-app
RUN cd /src/dotnet-function-app && \
    mkdir -p /home/site/wwwroot && \
    dotnet publish MyFunctionProj/*.csproj --output /home/site/wwwroot

FROM mcr.microsoft.com/azure-functions/dotnet:2.0
ENV AzureWebJobsScriptRoot=/home/site/wwwroot

COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]