const defaultPortWebsocket = 4000;
const defaultPortWww = 8000;

export interface Environment {
  apollo: {
    introspection: boolean
    playground: boolean
  }
  portWebSocket: number
  portWww: number
}

export const environment: Environment = {
  apollo: {
    introspection: process.env.APOLLO_INTROSPECTION === 'true',
    playground: process.env.APOLLO_PLAYGROUND === 'true'
  },
  portWebSocket: +(process.env.PORT_WS || defaultPortWebsocket),
  portWww: +(process.env.PORT_WWW || defaultPortWww)
};
