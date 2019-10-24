const defaultPortWww = 8085;
const defaultPortWebsocket = 8086;

export interface Environment {
  apollo: {
    introspection: boolean
    playground: boolean
  }
  portWebSocket: number
  portWww: number
  staticFilesPath: string
}

let env = process.env.NODE_ENV
if (env != 'production' && env != 'development') {
  env = 'development'
}

export const environment: Environment = {
  apollo: {
    introspection: process.env.APOLLO_INTROSPECTION === 'true',
    playground: process.env.APOLLO_PLAYGROUND === 'true'
  },
  portWebSocket: +(process.env.PORT_WS || defaultPortWebsocket),
  portWww: +(process.env.PORT_WWW || defaultPortWww)
};
