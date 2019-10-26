import path from 'path'

const defaultPortWww = 8085;
const isDevelopment = !!module.hot //app.get('env') == "development"
const staticFilesPath = path.resolve(path.dirname(process.argv[1]),
  isDevelopment ? "../../frontend/public" : "../public")

console.log("env.isDev = ", isDevelopment)

export interface Environment {
  isDebugLoggingEnabled: boolean
  apollo: {
    introspection: boolean
    playground: boolean
  }
  host: string
  port: number

  databaseConnection: {
    host: string
    port: number
    database: string
    user: string
    password: string
  }

  /** The limit for messages in database. Put 0 to disable. */
  dbMessageLimit: number

  /** Instead of removing the oldest message every time a single one message is added, batch removing old messages */
  dbMessageLimitRemovalBatchSize: number,

  // relative to output `server.js` file
  staticFilesPath: string
  isSecureHttpEnabled: boolean
  secret_session: string
  secret_dbPasswordSalt: string
}

export const environment: Environment = {
  isDebugLoggingEnabled: process.env.DEBUG_LOGGING ? new Boolean(process.env.DEBUG_LOGGING).valueOf() : isDevelopment,
  apollo: {
    introspection: process.env.APOLLO_INTROSPECTION === 'true',
    playground: process.env.APOLLO_PLAYGROUND === 'true'
  },
  host: '0.0.0.0',
  port: +(process.env.PORT || defaultPortWww),
  databaseConnection: {
    host: process.env.PGHOST || 'localhost',
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || 'postgres',
    database: process.env.PGDATABASE || 'postgres',
    port: +(process.env.PGPORT || 5432)
  },
  dbMessageLimit: +(process.env.DB_MESSAGE_LIMIT || 100),
  dbMessageLimitRemovalBatchSize: +(process.env.DB_MESSAGE_LIMIT_REMOVAL_BATCH_SIZE || 10),
  staticFilesPath,
  isSecureHttpEnabled: false, // TODO https not implemeneted
  secret_session: process.env.SECRET_SESSION || '123435rsedgfs',
  secret_dbPasswordSalt: process.env.SECRET_DB_PASSWORD_SALT || '654544124213'
};
