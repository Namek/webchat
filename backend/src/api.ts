import { GraphQLScalarType, Kind } from "graphql"
import { withFilter } from 'graphql-subscriptions'
import typeDefs from "!!raw-loader!./api.graphql"
import { ChatStateUpdate, Message, Person, ApiMutation } from './api_types'
import { AppState, User } from './state'

const CHAT_STATE_UPDATED = 'chatStateUpdated'

export default (state: AppState) => {
  const Query/*: ApiQuery*/ = {
    chatState: (root: any, { since }: any) => {
      const chatState: ChatStateUpdate = {
        people: state.repo.getPeople(),
        newMessages: state.repo.getMessages(since)
      }

      return chatState
    },
    checkAuthSession: (root: any, input: any, ctx: any) => {
      let user = state.userSessions.find(u => u.cookieSessionId == ctx.sessionID)

      if (!user) {
        return null
      }

      const ret: Person = {
        name: user.name,
        id: user.id,
        avatarSeed: user.avatarSeed
      }

      return ret
    }
  }

  const Mutation: ApiMutation = {
    logIn: (root, { name, passwordHash }, ctx) => {
      const person = state.repo.checkUserCredentialsOrCreateUser(name, passwordHash)

      if (!person) {
        throw new Error("You have passed wrong credentials.")
      }

      const user: User = {
        id: person.id!,
        name: person.name!,
        avatarSeed: person.avatarSeed!,
        cookieSessionId: ctx.sessionID
      }
      state.userSessions.push(user)

      const chatStateUpdated: ChatStateUpdate = {
        people: [person],
        newMessages: []
      }
      state.pubsub.publish(CHAT_STATE_UPDATED, { [CHAT_STATE_UPDATED]: chatStateUpdated })

      return person
    },
    logOut: (root, _, ctx) => {
      state.userSessions = state.userSessions.filter(u => u.cookieSessionId != ctx.sessionID)
      ctx.session.destroy(() => { })
      return null
    },
    addMessage: (root, { content }, ctx) => {
      console.log(`New message: ${content}`)

      // find out if this user is authorized, otherwise he can't post messages
      let user = state.userSessions.find(u => u.cookieSessionId == ctx.sessionID)

      if (!user) {
        throw new Error("You cannot add messages to the chat since you are not logged in.")
      }

      let personId = user.id
      const message = state.repo.addMessage(personId, content)

      const chatStateUpdated: ChatStateUpdate = {
        people: [],
        newMessages: [message]
      }

      state.pubsub.publish(CHAT_STATE_UPDATED, { [CHAT_STATE_UPDATED]: chatStateUpdated })

      return message.id!
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
    Mutation: Mutation as any, //Note: Either I or a compiler was sick that day.
    Subscription: {
      chatStateUpdated: {
        subscribe: withFilter(
          () => state.pubsub.asyncIterator([CHAT_STATE_UPDATED]),
          (payload, variables) => true
        )
      }
    }
  }

  return { resolvers, typeDefs }
}