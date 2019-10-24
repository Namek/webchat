-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Api.Mutation exposing (..)

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
import Json.Decode as Decode exposing (Decoder)


type alias AuthenticateOptionalArguments =
    { since : OptionalArgument Api.ScalarCodecs.Datetime }


type alias AuthenticateRequiredArguments =
    { name : String
    , passwordHash : String
    }


{-| Log in if account exists. Otherwise, register and log in.
The name is unique.

  - name -
  - passwordHash -
  - since -

-}
authenticate : (AuthenticateOptionalArguments -> AuthenticateOptionalArguments) -> AuthenticateRequiredArguments -> SelectionSet decodesTo Api.Object.SignInResult -> SelectionSet decodesTo RootMutation
authenticate fillInOptionals requiredArgs object_ =
    let
        filledInOptionals =
            fillInOptionals { since = Absent }

        optionalArgs =
            [ Argument.optional "since" filledInOptionals.since (Api.ScalarCodecs.codecs |> Api.Scalar.unwrapEncoder .codecDatetime) ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "authenticate" (optionalArgs ++ [ Argument.required "name" requiredArgs.name Encode.string, Argument.required "passwordHash" requiredArgs.passwordHash Encode.string ]) object_ identity


{-| -}
logOut : SelectionSet (Maybe Bool) RootMutation
logOut =
    Object.selectionForField "(Maybe Bool)" "logOut" [] (Decode.bool |> Decode.nullable)


type alias CreateMessageOptionalArguments =
    { content : OptionalArgument String }


{-|

  - content -

-}
createMessage : (CreateMessageOptionalArguments -> CreateMessageOptionalArguments) -> SelectionSet decodesTo Api.Object.ChatStateUpdate -> SelectionSet decodesTo RootMutation
createMessage fillInOptionals object_ =
    let
        filledInOptionals =
            fillInOptionals { content = Absent }

        optionalArgs =
            [ Argument.optional "content" filledInOptionals.content Encode.string ]
                |> List.filterMap identity
    in
    Object.selectionForCompositeField "createMessage" optionalArgs object_ identity
