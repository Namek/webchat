import { ChatStateUpdate, Message, Person } from './api_types'
import crypto from 'crypto'

const hashMd5 = (text: string) => crypto.createHash('md5').update(text).digest("hex")
const SECRET_SALT = "32523ter21"


// TODO temporary until database is implemented
const TMP_SUCCESS_PASSWORD = hashMd5(hashMd5("hithere") + SECRET_SALT)

function encryptPassword(password: string, key: string): string {
  // TODO encrypt with sha1 or sth
  return password + key
}

export default class Repository {
  private lastMessageId: number = 0
  private lastPersonId: number = 0

  // TODO these are temporary collections, normally there would be database
  messages: Array<Message> = []
  people: Array<Person> = []

  checkAuthSession(authToken: string): Person | null {
    // TODO
    return null
  }

  getMessages(since?: Date): Array<Message> {
    return this.messages
  }

  getPeople(): Array<Person> {
    return this.people
  }

  addMessage(authorId: number, content: string): Message {
    let id = ++this.lastMessageId

    // TODO queue removing messages over limit

    const message: Message = {
      id,
      authorId,
      datetime: new Date(),
      content: content
    }
    this.messages.push(message)

    return message
  }

  checkUserCredentialsOrCreateUser(name: string, passwordHash: string): Person | null {
    // TODO find person in DB
    let person: Person | null = this.people.find(p => p.name == name) || null
    const dbEncryptedPassword = TMP_SUCCESS_PASSWORD

    if (person) {
      // TODO change the key to get it from configuration/env
      if (dbEncryptedPassword != hashMd5(passwordHash + SECRET_SALT)) {
        person = null
      }
    }
    else {
      person = {
        id: ++this.lastPersonId,
        name,
        avatarSeed: 235234
      }
      this.people.push(person)
    }

    return person
  }
}
