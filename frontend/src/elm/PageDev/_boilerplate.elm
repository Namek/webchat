module PageDev._boilerplate exposing (Model, Msg, main, view)

import Browser
import Cmd.Extra
import Data.Context exposing (GlobalMsg)
import Html exposing (Html)
import Page.<your_page> as ThePage exposing (Msg(..))
import PageDev.DevCommon as Dev exposing (Msg(..))


main : Program () Model Msg
main =
    Browser.element
        { init = always <| Dev.init ThePage.init
        , view = view
        , update = \msg model -> Dev.update ThePage.update handlePageMsg handleGlobalCmd msg model
        , subscriptions = always Sub.none
        }


type alias Context =
    ThePage.Context Msg


type alias Model =
    Dev.Model ThePage.Model


type alias Msg =
    Dev.Msg ThePage.Msg


handlePageMsg : Model -> ThePage.Msg -> Maybe ( Model, Cmd Msg )
handlePageMsg model pageMsg =
    Nothing


handleGlobalCmd : Model -> GlobalMsg -> Maybe ( Model, Cmd Msg )
handleGlobalCmd model globalCmdMsg =
    Nothing


view : Model -> Html Msg
view model =
    Dev.view model <|
        ThePage.view (Dev.makeCtx model)