import express from 'express'
import http from 'http'
import WebSocket from 'ws'
import { ApolloServer, PubSub } from 'apollo-server-express'
import { ConnectionContext } from 'subscriptions-transport-ws'
import session from 'express-session'

import { environment } from './environment'
import ChatApi from './api'
import { AppState } from './state'
import Repository from './repository'
import { ApiContext } from './api_types'


const state: AppState = {
  pubsub: new PubSub(),
  repo: new Repository(),
  userSessions: []
}
const api = ChatApi(state)

// HTTP: GraphQL queries, mutations and hosting of static files (frontend). Only subscriptions go over WebSocket.

const app = express()

var sess: session.SessionOptions = {
  secret: environment.secret_session,
  cookie: {
    secure: false,
    httpOnly: true,
    // maxAge: 30 * 24 * 60 * 60 * 1000
  } as express.CookieOptions
}

if (environment.isSecureHttpEnabled) {
  app.set('trust proxy', 1)  // trust first proxy
  sess.cookie!.secure = true // serve secure cookies
}

app.use(session(sess))

const httpServer = http.createServer(app)
app.use(express.static(environment.staticFilesPath))

const gqlServer = new ApolloServer({
  typeDefs: api.typeDefs,
  resolvers: api.resolvers,
  introspection: environment.apollo.introspection,
  playground: environment.apollo.playground,
  context: async ({ req, connection }) => {
    if (req && req.session && req.sessionID) {
      return {
        session: req.session!,
        sessionID: req.sessionID!
      } as ApiContext
    }

    return {}
  },
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
