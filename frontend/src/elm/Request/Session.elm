module Request.Session exposing (LogInResult, LogOutResult, checkAuthSession, logIn, logOut)

import Api.Mutation as Mutation exposing (LogInRequiredArguments)
import Api.Object.Person
import Api.Query as Query
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import MD5


type alias LogInResult =
    { personId : Int
    , personName : String
    }


type alias LogInInput a =
    { a | name : String, password : String }


type alias LogOutResult =
    Maybe Bool


logIn : LogInInput a -> SelectionSet LogInResult RootMutation
logIn credentials =
    let
        args : LogInRequiredArguments
        args =
            { name = credentials.name
            , passwordHash = credentials.password |> MD5.hex
            }
    in
    Mutation.logIn
        args
        (SelectionSet.succeed LogInResult
            |> with Api.Object.Person.id
            |> with Api.Object.Person.name
        )


checkAuthSession : () -> SelectionSet (Maybe LogInResult) RootQuery
checkAuthSession () =
    Query.checkAuthSession
        (SelectionSet.succeed LogInResult
            |> with Api.Object.Person.id
            |> with Api.Object.Person.name
        )


logOut : () -> SelectionSet LogOutResult RootMutation
logOut () =
    Mutation.logOut
