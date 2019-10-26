# Web Chat

*Tech*: [NodeJS](https://nodejs.org) and [Elm](https://elm-lang.org)

#### Play right away

1. Boot it up with [docker-compose](https://docs.docker.com/compose/install/)

       docker-compose build
       docker-compose up

2. Open [http://localhost:8085](http://localhost:8085) in your browser.

## Features

- read chat as anonymous user
- log in / register using name+password, then chat with others
- communication: GraphQL
   - Query: getting chat state, check session based on cookie
   - Mutation: logIn, logOut, addMessage
   - and Subscription: chat updates
- frontend/UX: multiple messages of the same author in a row are grouped within 5 minutes

## Possible improvements

- Secure HTTP
- database migrations
- frontend: bundle JS code into one file
- backend: [detecting and closing broken connections](https://github.com/websockets/ws#how-to-detect-and-close-broken-connections)
- backend: store session not in-memory but in database so server restart wouldn't log out users
- frontend UX: better indications about connection status
- timezones need some care
- build: reduce size of Docker downloads


# Development

All env vars are defined in `/backend/src/environment.ts`. [dotenv](https://www.npmjs.com/package/dotenv) is imported so you can create `/backend/.env` file changing the defaults.

## Backend

    cd /backend
    set NODE_ENV=development
    npm run start


To generate Elm code for GraphQL API based on backend definitions you can launch backend in development environment and let the elm-graphql introspect for a schema:

    cd /backend
    npm run start
    npm run gen_graphql_api  # on another command line


## Frontend


Prerequisites: [dotnet script](https://github.com/filipw/dotnet-script), [Elm 0.19.1](https://guide.elm-lang.org/install/elm.html)


1. Build

For Windows it is:

    cd /frontend
    build_watch.bat

or

    cd /frontend
    dotnet script build.csx -- build watch debug


2. Host `/frontend/public` directory. The easiest way is to use backend in development mode.



# Production

Prerequisites: [PostgreSQL](https://www.postgresql.org/download/)

## Backend

    cd /backend
    set NODE_ENV=production
    npm run build

## Frontend

    cd /frontend
    dotnet script build.csx -- build
