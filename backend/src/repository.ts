import crypto from 'crypto'
import { Message, Person } from './api_types'
import { queryDb, initDatabaseIfNeeded } from './db'
import { environment } from './environment'

const hashMd5 = (text: string) => crypto.createHash('md5').update(text).digest("hex")

// table names, these have to be the same as in `./db_init.sql` file
const T_MESSAGES = "messages", T_PEOPLE = "people"


export default class Repository {
  private isMessageLimitEnabled = false
  private messageCount: number = 0
  private messageCap: number = 0

  async init() {
    await initDatabaseIfNeeded()

    const res = await queryDb(`SELECT COUNT(*) as c FROM ${T_MESSAGES}`)
    this.messageCount = +res.rows[0].c

    if (environment.dbMessageLimit > 0) {
      if (environment.dbMessageLimitRemovalBatchSize < 0) {
        throw new Error("environment.dbMessageLimitRemovalBatchSize has to be at least 0!")
      }

      this.messageCap = environment.dbMessageLimit + environment.dbMessageLimitRemovalBatchSize
      this.isMessageLimitEnabled = true

      await this.deleteOldMessages()
    }
  }

  private async deleteOldMessages() {
    // instead of removing the oldest message every time, batch removing old messages
    if (this.isMessageLimitEnabled && this.messageCount >= this.messageCap) {
      const messageCountToRemove = this.messageCount - environment.dbMessageLimit

      if (environment.isDebugLoggingEnabled) {
        console.log(`Removed ${messageCountToRemove} oldest messages:`)
      }

      await queryDb(`
        DELETE FROM ${T_MESSAGES} WHERE id IN (
          SELECT id FROM ${T_MESSAGES} ORDER BY datetime, id LIMIT ${messageCountToRemove}
        )
      `)

      this.messageCount -= messageCountToRemove
    }
  }

  async getMessages(since?: Date): Promise<Array<Message>> {
    // TODO support `since`
    return queryDb(`
      WITH t AS
        (SELECT * FROM ${T_MESSAGES} ORDER BY datetime DESC, id DESC LIMIT ${environment.dbMessageLimit})
      SELECT * FROM t ORDER BY datetime ASC, id ASC
    `)
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
      SELECT id, name, avatar_seed FROM ${T_PEOPLE}
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
    const message: Message = {
      authorId,
      datetime: new Date(),
      content: content
    }

    const res = await queryDb(`
      INSERT INTO ${T_MESSAGES} (content, author_id, datetime)
      VALUES ($1, $2, to_timestamp($3)) RETURNING id
    `, [
      message.content,
      message.authorId,
      message.datetime!.getTime() / 1000
    ])

    message.id = res.rows[0].id
    this.messageCount += 1

    await this.deleteOldMessages()

    return message
  }

  async checkUserCredentialsOrCreateUser(name: string, passwordHash: string): Promise<Person | null> {
    let res = await queryDb(`
      SELECT id, name, avatar_seed, password FROM ${T_PEOPLE} WHERE name=$1
    `, [name])

    const encryptedPassword = hashMd5(passwordHash + environment.secret_dbPasswordSalt)

    if (res.rows.length == 0) {
      // Create user and return it
      const newAvatarSeed = Math.floor(Math.random() * 1000000)
      res = await queryDb(`
        INSERT INTO ${T_PEOPLE}(name, password, avatar_seed)
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
