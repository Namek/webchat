import path from 'path'

const defaultPortWww = 8085;
const isDevelopment = !!module.hot //env == "development"
const staticFilesPath = path.resolve(path.dirname(process.argv[1]),
  isDevelopment ? "../../frontend/public" : "./public")


export interface Environment {
  apollo: {
    introspection: boolean
    playground: boolean
  }
  port: number

  // relative to output `server.js` file
  staticFilesPath: string
}

export const environment: Environment = {
  apollo: {
    introspection: process.env.APOLLO_INTROSPECTION === 'true',
    playground: process.env.APOLLO_PLAYGROUND === 'true'
  },
  port: +(process.env.PORT || defaultPortWww),
  staticFilesPath
};
