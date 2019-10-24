export interface Message {
  id: number,
  content: string,
  authorId: number,
  datetime: Date
}
export interface Person {
  id: number
  name: string
  avatarSeed: number
}
export interface ChatStateUpdate {
  people: Array<Person>,
  newMessages: Array<Message>
}
export interface SignInResult {
  personId: number,
  personName: number
}
export interface ApiQuery {
  chatState: (since: Date) => ChatStateUpdate
  checkAuthSession: () => SignInResult | null
}
export interface ApiMutation {
  logIn: (root: any, input: { name: String, passwordHash: String, since?: Date }) => SignInResult
  logOut: () => null
  addMessage: (root: any, input: { content: String }) => number
}
