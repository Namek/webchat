module Page exposing (..)

import Data.Context exposing (GlobalMsg)
import Data.Session exposing (SessionState(..))
import Element exposing (Element, alignRight, centerX, column, fill, height, padding, spacing, text, width)
import Misc exposing (viewIf)
import Page.Chat
import Page.Errored
import Page.Login
import Ports exposing (ConnectionStatus(..))


type Page
    = Blank
    | Errored Page.Errored.Model
    | Login Page.Login.Model
    | Chat Page.Chat.Model


frame : (GlobalMsg -> msg) -> Bool -> SessionState -> Page -> Element msg -> Element msg
frame lift isLoggedIn session activePage pageContent =
    let
        content =
            column [ width fill, height fill, spacing 10 ]
                [ viewIf isLoggedIn <| Element.el [ alignRight, padding 3 ] <| viewTopBar session Connected
                , Element.el [ centerX, width fill, height fill ] pageContent
                ]
    in
    Element.el
        [ width fill, height fill ]
        content


viewTopBar : SessionState -> ConnectionStatus -> Element msg
viewTopBar sesionState topBarState =
    -- TODO: display some message about connection state
    case sesionState of
        LoggedSession session ->
            text "Log out"

        GuestSession ->
            text "Log in"
