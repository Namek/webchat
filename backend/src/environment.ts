import path from 'path'

const defaultPortWww = 8085;
const isDevelopment = !!module.hot //app.get('env') == "development"
const staticFilesPath = path.resolve(path.dirname(process.argv[1]),
  isDevelopment ? "../../frontend/public" : "../public")

console.log("env.isDev = ", isDevelopment)

export interface Environment {
  apollo: {
    introspection: boolean
    playground: boolean
  }
  host: string
  port: number

  // relative to output `server.js` file
  staticFilesPath: string
  isSecureHttpEnabled: boolean
  secret_session: string
}

export const environment: Environment = {
  apollo: {
    introspection: process.env.APOLLO_INTROSPECTION === 'true',
    playground: process.env.APOLLO_PLAYGROUND === 'true'
  },
  host: '0.0.0.0',
  port: +(process.env.PORT || defaultPortWww),
  staticFilesPath,
  isSecureHttpEnabled: false, // TODO https not implemeneted
  secret_session: process.env.SECRET_SESSION || '123435rsedgfs'
};
