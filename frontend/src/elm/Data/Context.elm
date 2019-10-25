module Data.Context exposing (..)

import Data.Session exposing (..)
import Route exposing (Route)
import Time


{-| Typical usage - a context type for specific Page:

    type alias Context msg =
        ContextData Model Msg msg

-}
type alias ContextData model localMsg rootMsg =
    { model : model
    , lift : localMsg -> rootMsg
    , time : Time.Posix
    , timezone : Time.Zone
    }


{-| Typical usage - a context type for specific Page that needs user to be logged in to see the page:

    type alias Context msg =
        Logged (ContextData Model Msg msg)

-}
type alias Logged ctx =
    { ctx
        | session : Session
    }


{-| Context for a Page that accepts both anonymous and logged users.

    type alias Context msg =
        Maybe Logged (ContextData Model Msg msg)

-}
type alias MaybeLogged ctx =
    { ctx
        | session : SessionState
    }


type GlobalMsg
    = Navigate Route
    | SetSession (Maybe Session)
      -- it's useful to hide scrollbars in the window for a modal window
    | SetScrollbarsVisibility Bool
    | RequestTimeUpdate
