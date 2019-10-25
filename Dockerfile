########################
### Build
###

FROM mcr.microsoft.com/dotnet/core/sdk:2.2 as build

# Install NodeJS
RUN apt-get update
RUN apt-get -y install gnupg2
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# Install elm and dotnet-script
WORKDIR /bin
RUN curl -sL https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz --output elm.gz && \
    gunzip elm.gz && chmod +x elm && \
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
COPY frontend/ ./
RUN  dotnet script build.csx build && ls /frontend && ls /frontend/public


########################
### Runtime
###

FROM node:12-buster as runtime
WORKDIR /app

COPY --from=build /backend ./
COPY --from=build /frontend/public ./public


EXPOSE 8085
ENV NODE_ENV production
CMD [ "node", "/app/dist/server.js" ]
