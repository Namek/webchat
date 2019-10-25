module Page exposing (..)

import Data.Context exposing (GlobalMsg)
import Data.Session exposing (SessionState(..))
import Element exposing (Element, alignRight, centerX, column, fill, height, inFront, link, padding, paddingXY, spacing, text, width)
import Element.Font as Font
import Misc exposing (viewIf)
import Misc.Colors as Colors
import Page.Chat
import Page.Errored
import Page.Login
import Ports exposing (ConnectionStatus(..))
import Route


type Page
    = Blank
    | Errored Page.Errored.Model
    | Login Page.Login.Model
    | Chat Page.Chat.Model


frame : (GlobalMsg -> msg) -> Bool -> SessionState -> Page -> Element msg -> Element msg
frame lift isLoggedIn session activePage pageContent =
    let
        content =
            column
                [ width fill
                , height fill
                , spacing 10
                , inFront <|
                    viewIf isLoggedIn <|
                        Element.el [ alignRight, paddingXY 40 10 ] <|
                            viewTopBar session Connected
                ]
                [ Element.el [ centerX, width fill, height fill ] pageContent
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
            link [ Font.color Colors.blue500, Font.size 14 ]
                { url = Route.routeToString Route.Logout
                , label = text "Log out"
                }

        GuestSession ->
            Element.none
