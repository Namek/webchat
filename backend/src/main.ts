import express from 'express'
import { ApolloServer } from 'apollo-server-express'

import { environment } from './environment'
import { resolvers, typeDefs } from './api'

// WebSocket: GraphQL (auth, chat messaging, chat updates)

const appWebSocket = express()

const gqlServer = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: environment.apollo.introspection,
  playground: environment.apollo.playground,
})

gqlServer.applyMiddleware({ app: appWebSocket, path: '/api' })

appWebSocket.listen(environment.portWebSocket, () => {
  console.log(`🚀 WebSocket (GraphQL) server ready at http://localhost:${environment.portWebSocket}${gqlServer.graphqlPath}`)
})


// WWW (http): host static files, frontend

const appWww = express()

appWww.listen(environment.portWww, () => {
  console.log(`WWW server ready at http://localhost/${environment.portWww}`)
})

appWww.get('/', (req, res) => {
  res.send("hey")
})


if (module.hot) {
  module.hot.accept()
  module.hot.dispose(() => gqlServer.stop())
}
