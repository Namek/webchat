module Data.Session exposing
    ( Session
    , SessionState(..)
    , unpackSession
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)


{-| If one has access to this data then he's logged in.
-}
type alias Session =
    { id : Int
    , name : String
    }


type SessionState
    = LoggedSession Session
    | GuestSession


unpackSession : SessionState -> Maybe Session
unpackSession state =
    case state of
        LoggedSession session ->
            Just session

        GuestSession ->
            Nothing
