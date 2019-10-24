module Request.Common exposing
    ( decodeChatMessage
    , decodeChatStateUpdate
    , decodeDatetime
    , decodePerson
    , encodeDatetime
    , sendMutationRequest
    , sendQueryRequest
    )

import Api.Object
import Api.Object.ChatStateUpdate
import Api.Object.Message
import Api.Object.Person
import Api.Scalar
import Data.Chat exposing (ChatMessage, ChatStateUpdate, Person)
import Graphql.Http as Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import Misc.Collections exposing (fromListBy)
import RemoteData exposing (RemoteData)
import Time exposing (Posix)


graphQlApiUrl =
    "/api"


sendQueryRequest : (RemoteData (Http.Error response) response -> msg) -> SelectionSet response RootQuery -> Cmd msg
sendQueryRequest dataHandlerMsg query =
    query
        -- TODO replace HTTP with WebSocket
        |> Http.queryRequest graphQlApiUrl
        |> Http.send (RemoteData.fromResult >> dataHandlerMsg)


sendMutationRequest : (RemoteData (Http.Error response) response -> msg) -> SelectionSet response RootMutation -> Cmd msg
sendMutationRequest dataHandlerMsg query =
    query
        |> Http.mutationRequest graphQlApiUrl
        |> Http.send (RemoteData.fromResult >> dataHandlerMsg)


decodeDatetime : Api.Scalar.Datetime -> Time.Posix
decodeDatetime (Api.Scalar.Datetime datetime) =
    datetime
        |> String.toInt
        |> Maybe.withDefault 0
        |> Time.millisToPosix


encodeDatetime : Time.Posix -> Api.Scalar.Datetime
encodeDatetime time =
    time
        |> Time.posixToMillis
        |> String.fromInt
        |> Api.Scalar.Datetime


decodeChatStateUpdate : SelectionSet ChatStateUpdate Api.Object.ChatStateUpdate
decodeChatStateUpdate =
    SelectionSet.succeed ChatStateUpdate
        |> with
            (Api.Object.ChatStateUpdate.people decodePerson
                |> SelectionSet.map (fromListBy .id)
            )
        |> with (Api.Object.ChatStateUpdate.newMessages decodeChatMessage)


decodePerson : SelectionSet Person Api.Object.Person
decodePerson =
    SelectionSet.succeed Person
        |> with Api.Object.Person.id
        |> with Api.Object.Person.name
        |> with Api.Object.Person.avatarSeed


decodeChatMessage =
    SelectionSet.succeed ChatMessage
        |> with Api.Object.Message.id
        |> with Api.Object.Message.content
        |> with Api.Object.Message.authorId
        |> with (Api.Object.Message.datetime |> SelectionSet.map decodeDatetime)
