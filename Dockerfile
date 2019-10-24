########################
### Build
###

FROM mcr.microsoft.com/dotnet/core/sdk:2.1 as build

# Install NodeJS
RUN apt-get update
RUN apt-get -y install gnupg2
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# Install elm and dotnet-script
WORKDIR /bin
RUN curl -sL https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz --output elm.tar.gz && \
    tar -xzf elm.tar.gz && rm elm.tar.gz && \
    dotnet tool install -g dotnet-script && \
    ln -sfn /root/.dotnet/tools/dotnet-script /bin/dotnet-script

# Build: Backend
WORKDIR /backend/
COPY backend/package.json backend/package-lock.json ./
RUN npm install

COPY backend/ ./
RUN NODE_ENV=production npm run build

# Build: Frontend
WORKDIR /frontend/
COPY frontend/src/ ./src
COPY frontend/build.csx ./
RUN  dotnet script build.csx build


########################
### Runtime
###

FROM node:12-buster as runtime
WORKDIR /app

COPY --from=build /backend/dist ./
COPY --from=build /frontend/public ./public


EXPOSE 8000
EXPOSE 4000
ENTRYPOINT [ "NODE_ENV=production node /app/server.js" ]
