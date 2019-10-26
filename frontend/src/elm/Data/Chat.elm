module Data.Chat exposing (..)

import Dict exposing (Dict)
import Time


type alias PersonId =
    Int


type alias Person =
    { id : PersonId
    , name : String
    , avatarSeed : Int
    }


type alias People =
    Dict PersonId Person


type alias MessageId =
    Int


type alias ChatMessage =
    { id : MessageId
    , content : String
    , authorId : PersonId

    -- UTC time
    , datetime : Time.Posix
    }


type alias ChatStateUpdate =
    { people : People
    , newMessages : List ChatMessage
    }


minutesToPassToGroupMessage =
    5


personName : PersonId -> People -> String
personName personId people =
    Dict.get personId people |> Maybe.map .name |> Maybe.withDefault "👻"


personAvatarSeed : PersonId -> People -> Int
personAvatarSeed personId people =
    Dict.get personId people |> Maybe.map .avatarSeed |> Maybe.withDefault 0
