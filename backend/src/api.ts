import { GraphQLScalarType, Kind } from "graphql"
import { PubSub, withFilter } from 'graphql-subscriptions'
import typeDefs from "!!raw-loader!./api.graphql"
import { ChatStateUpdate, Message } from './api_types'
import * as Repo from './repo'

const pubsub = new PubSub()

const Query/*: ApiQuery*/ = {
  chatState: (root: any, { since }: any) => {
    const chatState: ChatStateUpdate = {
      people: Repo.getPeople(),
      newMessages: Repo.getMessages(since)
    }

    return chatState
  },
  checkAuthSession: () => {
    const chatState: ChatStateUpdate = {
      people: [],
      newMessages: []
    }

    // TODO

    return { personName: "nmk", personId: 1, chatState }
  }
}

const Mutation/*: ApiMutation*/ = {
  logIn: (root: any, { name, passwordHash, sifnce }: any) => {
    // TODO
    const chatState: ChatStateUpdate = {
      people: [],
      newMessages: []
    }

    return { personName: "asdasd", personId: 1, chatState }

  },
  logOut: () => {
    // TODO
    return null
  },
  addMessage: (root: any, { content }: any) => {
    console.log(root, content)

    // TODO find out if he's authorized
    let personId = 1
    const message = Repo.addMessage(personId, content)

    const chatStateUpdated: ChatStateUpdate = {
      people: [],
      newMessages: [message]
    }

    pubsub.publish('chatStateUpdated', chatStateUpdated)

    return message.id
  }
}

const resolvers = {
  Datetime: new GraphQLScalarType({
    name: 'Datetime',
    description: 'date+time as Integer number, Unix epoch',
    parseValue(value) {
      return new Date(value)
    },
    serialize(value: Date) {
      return value.getTime()
    },
    parseLiteral(ast) {
      if (ast.kind === Kind.INT) {
        return parseInt(ast.value, 10)
      }
      return null
    }
  }),
  Query,
  Mutation,
  Subscription: {
    chatStateUpdated: {
      subscribe: withFilter(
        () => pubsub.asyncIterator('chatStateUpdated'),
        (payload, variables) => true
      )
    }
  }
}

export { resolvers, typeDefs }