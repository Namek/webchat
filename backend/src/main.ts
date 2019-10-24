import express from 'express'
import { ApolloServer } from 'apollo-server-express'

import { environment } from './environment'
import { resolvers, typeDefs } from './api'

// WWW: GraphQL queries, mutations and hosting of static files (frontend)

const app = express()
app.use(express.static(environment.staticFilesPath))

const gqlServer = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: environment.apollo.introspection,
  playground: environment.apollo.playground,
})

gqlServer.applyMiddleware({ app: app, path: '/api' })

const appWwwServer = app.listen(environment.portWww, () => {
  console.log(`🚀 WWW server ready at http://localhost/${environment.portWww}`)
  //console.log(`🚀 GraphQL server ready at http://localhost:${environment.portWebSocket}${gqlServer.graphqlPath}`)
})


// TODO WebSocket GraphQL Subscriptions (notifying user about state changes on the chat)


if (module.hot) {
  module.hot.accept()
  module.hot.dispose(() => {
    gqlServer.stop()
    appWwwServer.close()
  })
}
