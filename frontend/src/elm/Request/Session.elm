module Request.Session exposing (SignInResult, SignOutResult, authorize)

import Api.Mutation as Mutation exposing (AuthenticateRequiredArguments)
import Api.Object
import Api.Object.ChatStateUpdate
import Api.Object.Message
import Api.Object.Person
import Api.Object.SignInResult
import Data.Chat exposing (ChatMessage, ChatStateUpdate, People, Person)
import Data.Session exposing (Session)
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import MD5
import Misc.Collections exposing (fromListBy)
import Request.Common exposing (decodeDatetime)


type alias SignInResult =
    { chatState : ChatStateUpdate
    , personId : Int
    , personName : String
    }


type alias SignInInput a =
    { a | name : String, password : String }


type alias SignOutResult =
    { userId : Maybe Int }


authorize : SignInInput a -> SelectionSet SignInResult RootMutation
authorize credentials =
    let
        input : AuthenticateRequiredArguments
        input =
            { name = credentials.name
            , passwordHash = credentials.password |> MD5.hex
            }
    in
    Mutation.authenticate identity
        input
        (SelectionSet.succeed SignInResult
            |> with (Api.Object.SignInResult.chatState decodeChatStateUpdate)
            |> with Api.Object.SignInResult.personId
            |> with Api.Object.SignInResult.personName
        )


decodeChatStateUpdate : SelectionSet ChatStateUpdate Api.Object.ChatStateUpdate
decodeChatStateUpdate =
    SelectionSet.succeed ChatStateUpdate
        |> with
            (Api.Object.ChatStateUpdate.newPeople decodePerson
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



--checkSession : () -> SelectionSet (Maybe SignInResult) RootMutation
--checkSession () =
--    Mutation.checkSession
--        (SelectionSet.succeed Session
--            |> with CheckSessionResult.id
--            |> with CheckSessionResult.email
--            |> with CheckSessionResult.name
--        )
--
--signOut : () -> SelectionSet SignOutResult RootMutation
--signOut () =
--    Mutation.signOut
--        (SelectionSet.succeed SignOutResult
--            |> with SignOutResult.userId
--        )
