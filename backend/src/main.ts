import express from 'express'
import http from 'http'
import WebSocket from 'ws'
import { ApolloServer } from 'apollo-server-express'
import { ConnectionContext } from 'subscriptions-transport-ws';

import { environment } from './environment'
import { resolvers, typeDefs } from './api'

// HTTP: GraphQL queries, mutations and hosting of static files (frontend). Only subscriptions go over WebSocket.

const app = express()
const httpServer = http.createServer(app)
app.use(express.static(environment.staticFilesPath))

const gqlServer = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: environment.apollo.introspection,
  playground: environment.apollo.playground,
  subscriptions: {
    onConnect: (connectionParams: any, socket: WebSocket, context: ConnectionContext) => {
      console.log('subscription connect', connectionParams)
    },
    onDisconnect: (socket: WebSocket, context: ConnectionContext) => {
      console.log('disconnected')
    }
  }
})

gqlServer.applyMiddleware({ app: app, path: '/api' })
gqlServer.installSubscriptionHandlers(httpServer)

httpServer.listen(environment.port, () => {
  console.log(`🚀 WWW server ready at http://localhost/${environment.port}`)
  console.log(`🚀 Subscriptions ready at ws://localhost:${environment.port}${gqlServer.subscriptionsPath}`)
})


// TODO WebSocket GraphQL Subscriptions (notifying user about state changes on the chat)


if (module.hot) {
  module.hot.accept()
  module.hot.dispose(() => {
    gqlServer.stop()
    httpServer.close()
  })
}
