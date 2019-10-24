module Request.Message exposing (..)

import Api.Mutation as Mutation
import Api.Object
import Api.Query as Query
import Api.Subscription as Subscription
import Data.Chat exposing (ChatStateUpdate)
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..), fromMaybe)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Request.Common exposing (decodeChatStateUpdate, encodeDatetime)
import Time


getChatState : Maybe Time.Posix -> SelectionSet ChatStateUpdate Graphql.Operation.RootQuery
getChatState since =
    Query.chatState
        (\arg ->
            { arg
                | since = fromMaybe since |> Graphql.OptionalArgument.map encodeDatetime
            }
        )
        decodeChatStateUpdate


addMessage : String -> SelectionSet () RootMutation
addMessage text =
    Mutation.addMessage (always { content = Present text })
        |> SelectionSet.map (always ())


sub_chatStateUpdate : SelectionSet ChatStateUpdate Graphql.Operation.RootSubscription
sub_chatStateUpdate =
    Subscription.chatStateUpdated decodeChatStateUpdate
