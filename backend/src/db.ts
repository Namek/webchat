import pg from 'pg'
import dbSqlCodeForInit from "!!raw-loader!./db_init.sql"

export async function queryDb(query: string, values: any[] = []) {
  const client = new pg.Client({
    host: process.env.PGHOST || 'localhost',
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || 'postgres',
    database: process.env.PGDATABASE || 'postgres',
    port: +(process.env.PGPORT || 5432)
  })
  await client.connect()
  const res = await client.query(query, values)
  await client.end()
  return res
}

/** Poor man's database migration. Initialization only. */
export async function initDatabaseIfNeeded() {
  await queryDb(dbSqlCodeForInit)
}