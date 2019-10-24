-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Api.Object.Message exposing (..)

import Api.InputObject
import Api.Interface
import Api.Object
import Api.Scalar
import Api.ScalarCodecs
import Api.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode


{-| -}
id : SelectionSet Int Api.Object.Message
id =
    Object.selectionForField "Int" "id" [] Decode.int


{-| -}
content : SelectionSet String Api.Object.Message
content =
    Object.selectionForField "String" "content" [] Decode.string


{-| -}
authorId : SelectionSet Int Api.Object.Message
authorId =
    Object.selectionForField "Int" "authorId" [] Decode.int


{-| -}
datetime : SelectionSet Api.ScalarCodecs.Datetime Api.Object.Message
datetime =
    Object.selectionForField "ScalarCodecs.Datetime" "datetime" [] (Api.ScalarCodecs.codecs |> Api.Scalar.unwrapCodecs |> .codecDatetime |> .decoder)
