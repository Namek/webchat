import { ChatStateUpdate, Message, Person } from './api_types'

function getMessages(since?: Date): Array<Message> {
  // TODO get from database
  return []
}

function getPeople(): Array<Person> {
  // TODO
  return []
}

function addMessage(authorId: number, content: string): Message {
  // TODO add message to database, get it's id
  let msgId = 1000

  // TODO queue removing messages over limit

  const message: Message = {
    id: msgId,
    authorId,
    datetime: new Date(),
    content: content
  }

  return message
}

export { getPeople, getMessages, addMessage }