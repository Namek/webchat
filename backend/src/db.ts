import pg from 'pg'
import dbSqlCodeForInit from "!!raw-loader!./db_init.sql"
import { environment } from './environment'

export async function queryDb(query: string, values: any[] = []) {
  const client = new pg.Client(environment.databaseConnection)
  await client.connect()
  const res = await client.query(query, values)
  await client.end()
  return res
}

/** Poor man's database migration. Initialization only. */
export async function initDatabaseIfNeeded() {
  await queryDb(dbSqlCodeForInit)
}