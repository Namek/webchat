import crypto from 'crypto'
import { ChatStateUpdate, Message, Person } from './api_types'
import { queryDb } from './db'


const hashMd5 = (text: string) => crypto.createHash('md5').update(text).digest("hex")
const SECRET_SALT = "32523ter21"


// TODO temporary until database is implemented
const TMP_SUCCESS_PASSWORD = hashMd5(hashMd5("hithere") + SECRET_SALT)


export default class Repository {
  private lastPersonId: number = 0

  // TODO these are temporary collections, normally there would be database
  people: Array<Person> = []


  async getMessages(since?: Date): Promise<Array<Message>> {
    // TODO support `since`
    return queryDb("SELECT * FROM messages")
      .then(res => res.rows.map(row =>
        ({
          id: row.id,
          authorId: row.author_id,
          content: row.content,
          datetime: new Date(row.datetime)
        } as Message)
      ))
  }

  getPeople(): Array<Person> {
    return this.people
  }

  async addMessage(authorId: number, content: string): Promise<Message> {
    // TODO queue removing messages over limit

    const message: Message = {
      authorId,
      datetime: new Date(),
      content: content
    }

    const res = await queryDb(`
      INSERT INTO messages (content, author_id, datetime)
      VALUES ($1, $2, to_timestamp($3)) RETURNING id
    `, [
      message.content,
      message.authorId,
      message.datetime!.getTime() / 1000
    ])

    message.id = res.rows[0].id

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
