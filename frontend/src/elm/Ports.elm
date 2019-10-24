port module Ports exposing (..)

import Json.Decode as D
import Json.Encode as E
import RemoteData exposing (RemoteData)


port gotChatStateUpdate : (D.Value -> msg) -> Sub msg


port socketStatusConnected : (() -> msg) -> Sub msg


port socketStatusReconnecting : (() -> msg) -> Sub msg


type ConnectionStatus
    = NotConnected
    | Connected
    | Reconnecting
