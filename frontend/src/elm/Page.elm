module Page exposing (..)

import Data.Context exposing (GlobalMsg)
import Data.Session exposing (SessionState(..))
import Element exposing (Element, centerX, column, fill, spacing, text, width)
import Misc exposing (viewIf)
import Page.Chat
import Page.Errored
import Page.Login


type Page
    = Blank
    | Errored Page.Errored.Model
    | Login Page.Login.Model
    | Chat Page.Chat.Model


type TopBarState
    = AllOk
    | HavingConnectionIssues


frame : (GlobalMsg -> msg) -> Bool -> SessionState -> Page -> Element msg -> Element msg
frame lift isLoggedIn session activePage pageContent =
    let
        content =
            column [ width fill, spacing 10 ]
                [ viewIf isLoggedIn <| Element.el [ centerX ] <| viewTopBar session AllOk
                , Element.el [ centerX, width fill ] pageContent
                ]
    in
    Element.el
        [ width fill ]
        content


viewTopBar : SessionState -> TopBarState -> Element msg
viewTopBar sesionState topBarState =
    -- TODO: display some message about connection state
    case sesionState of
        LoggedSession session ->
            text "Log out"

        GuestSession ->
            text "Log in"
