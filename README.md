# Web Chat

NodeJS and Elm

# Play right away

    TODO docker -p 4000



# Development

Environment configuration:

* PORT_WWW - HTTP for hosting index.html, scripts, styles
* PORT_WS - WebSocket communications

## Backend

    cd /backend
    set NODE_ENV=development
    npm run start


To generate Elm code for GraphQL API based on backend definitions run backend in development environment and let the elm-graphql introspect for schema:

    cd /backend
    npm run start
    npm run gen_graphql_api  # on another command line

## Frontend

    TODO


# Production

## Backend

    cd /backend
    set NODE_ENV=production
    npm run build

## Frontend

    TODO