import crypto from 'crypto'
import { Message, Person } from './api_types'
import { queryDb } from './db'


const hashMd5 = (text: string) => crypto.createHash('md5').update(text).digest("hex")

// TODO change the key to get it from configuration/env
const SECRET_SALT = "32523ter21"


export default class Repository {
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

  async getPeople(): Promise<Array<Person>> {
    return queryDb(`
      SELECT id, name, avatar_seed FROM people
    `)
      .then(res => res.rows.map(row =>
        ({
          id: row.id,
          name: row.name,
          avatarSeed: row.avatar_seed
        } as Person)
      ))
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

  async checkUserCredentialsOrCreateUser(name: string, passwordHash: string): Promise<Person | null> {
    let res = await queryDb(`
      SELECT id, name, avatar_seed, password FROM people WHERE name=$1
    `, [name])

    const encryptedPassword = hashMd5(passwordHash + SECRET_SALT)

    if (res.rows.length == 0) {
      // Create user and return it
      const newAvatarSeed = Math.floor(Math.random() * 1000000)
      res = await queryDb(`
        INSERT INTO people(name, password, avatar_seed)
        VALUES ($1, $2, $3) RETURNING id
      `, [
        name, encryptedPassword, newAvatarSeed
      ])

      return {
        id: res.rows[0].id,
        name,
        avatarSeed: newAvatarSeed
      } as Person
    }
    else {
      const row = res.rows[0]

      // check password
      if (row.password != encryptedPassword) {
        return null
      }
      else {
        return {
          id: row.id,
          name: row.name,
          avatarSeed: row.avatar_seed
        } as Person
      }
    }
  }
}
