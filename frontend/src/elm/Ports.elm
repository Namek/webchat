port module Ports exposing (..)

import Json.Decode as D


port gotChatStateUpdate : (D.Value -> msg) -> Sub msg


port createSubscriptions : String -> Cmd msg


port socketStatusConnected : (() -> msg) -> Sub msg


port socketStatusReconnecting : (() -> msg) -> Sub msg


type ConnectionStatus
    = NotConnected
    | Connected
    | Reconnecting
