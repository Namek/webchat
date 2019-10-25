export interface Message {
  id?: number,
  content?: string,
  authorId?: number,
  datetime?: Date
}
export interface Person {
  id?: number
  name?: string
  avatarSeed?: number
}
export interface ChatStateUpdate {
  people?: Array<Person>,
  newMessages?: Array<Message>
}
export interface ApiQuery {
  chatState: (since: Date) => ChatStateUpdate
  checkAuthSession: () => Person | null
}
export interface ApiMutation {
  logIn: (root: any, input: { name: string, passwordHash: string }, ctx: ApiContext) => Person
  logOut: (root: any, input: any, ctx: ApiContext) => null
  addMessage: (root: any, input: { content: string }, ctx: ApiContext) => number
}
export interface ApiContext {
  sessionID: string
  session: Express.Session
}