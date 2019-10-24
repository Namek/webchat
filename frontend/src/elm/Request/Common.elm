module Request.Common exposing
    ( decodeDatetime
    , sendMutationRequest
    , sendQueryRequest
    )

import Api.Scalar
import Graphql.Http as Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)
import RemoteData exposing (RemoteData)
import Time exposing (Posix)


graphQlApiUrl =
    "/api"


sendQueryRequest : (RemoteData (Http.Error response) response -> msg) -> SelectionSet response RootQuery -> Cmd msg
sendQueryRequest dataHandlerMsg query =
    query
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
