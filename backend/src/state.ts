import { PubSub } from "graphql-subscriptions";
import Repository from './repository'

export interface AppState {
    pubsub: PubSub
    repo: Repository

    /** List of users authorized to post messages on chat */
    userSessions: Array<User>
}

export interface User {
    cookieSessionId: string
    id: number
    name: string
    avatarSeed: number
}