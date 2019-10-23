import { GraphQLScalarType, Kind } from "graphql"
import typeDefs from "!!raw-loader!./api.graphql"


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
  Query: {
    chatState: (root: any, {since}: any) => {
      console.log(since)

      return ["message1", "message2", "message3"]
    }
  },
  Mutation: {
    authenticate: (root: any) => {
      // TODO
    },
    logOut: () => {
      // TODO
    }
  }
}

export { resolvers, typeDefs }