module PageDev.Chat exposing (Model, Msg, main, view)

import Browser
import Cmd.Extra
import Data.Chat exposing (ChatMessage, People, Person, minutesToPassToGroupMessage)
import Data.Context exposing (GlobalMsg(..))
import Dict
import Html exposing (Html)
import Page.Chat as ThePage exposing (ChatStateUpdate, Msg(..))
import PageDev.DevCommon as Dev exposing (Msg(..))
import Process
import RemoteData
import Task
import Time
import Time.Extra exposing (Interval(..))


main : Program () Model Msg
main =
    Browser.element
        { init = always <| Dev.init ThePage.init
        , view = view
        , update = \msg model -> Dev.update ThePage.update handlePageMsg handleGlobalCmd msg model
        , subscriptions = \_ -> Time.every 5000 Dev.SetTime
        }


type alias Context =
    ThePage.Context Msg


type alias Model =
    Dev.Model ThePage.Model


type alias Msg =
    Dev.Msg ThePage.Msg


handlePageMsg : Model -> ThePage.Msg -> Maybe ( Model, Cmd Msg )
handlePageMsg model pageMsg =
    let
        secondsAgo : Int -> Time.Posix
        secondsAgo secondsBack =
            Time.Extra.add Second -secondsBack model.timezone (Debug.log "curtime" model.time)
    in
    case pageMsg of
        UpdateChatStateSince since ->
            let
                testPeople : People
                testPeople =
                    Dict.empty
                        |> Dict.insert 1
                            { id = 1, name = "Julie", email = "julie@dot.com", timezone = Time.utc, avatarUrl = "" }
                        |> Dict.insert 2
                            { id = 2, name = "Margharet", email = "marghie@dot.com", timezone = Time.utc, avatarUrl = "" }

                testMessages : List ChatMessage
                testMessages =
                    [ { id = 1, content = "Hello there!", authorId = 1, datetime = secondsAgo <| (5 + minutesToPassToGroupMessage) * 60 - 12 }
                    , { id = 2, content = ":)", authorId = 1, datetime = secondsAgo <| (5 + minutesToPassToGroupMessage) * 60 - 1 }

                    -- here's time separation for next message group of same author
                    , { id = 3, content = "How's your day??", authorId = 1, datetime = secondsAgo <| 5 * 60 + 1 }
                    , { id = 4, content = "Hi!", authorId = 2, datetime = secondsAgo <| (3 * 60) + 17 }
                    , { id = 5, content = "Great!", authorId = 2, datetime = secondsAgo <| (3 * 60) + 3 }
                    ]

                testUpdate : ChatStateUpdate
                testUpdate =
                    { newPeople = testPeople, newMessages = testMessages }

                answerWithMessages =
                    Process.sleep 100
                        |> Task.perform
                            (always <| GotPageMsg <| UpdateChatStateSince_Response (RemoteData.succeed testUpdate))
            in
            Just ( model, Cmd.batch [ answerWithMessages ] )

        SendMessage content ->
            let
                newMessages : List ChatMessage
                newMessages =
                    [ { id = 100, content = content, authorId = 1, datetime = secondsAgo <| (5 + minutesToPassToGroupMessage) * 60 - 12 } ]

                testUpdate : ChatStateUpdate
                testUpdate =
                    { newPeople = Dict.empty, newMessages = newMessages }

                answerWithNewMessage =
                    Process.sleep 100
                        |> Task.perform
                            (always <| GotPageMsg <| UpdateChatStateSince_Response (RemoteData.succeed testUpdate))
            in
            Just ( model, Cmd.batch [ answerWithNewMessage ] )

        _ ->
            Nothing


handleGlobalCmd : Model -> GlobalMsg -> Maybe ( Model, Cmd Msg )
handleGlobalCmd model globalCmdMsg =
    case globalCmdMsg of
        RequestTimeUpdate ->
            Just ( model, Task.perform Dev.SetTime Time.now )

        _ ->
            Nothing


view : Model -> Html Msg
view model =
    Dev.view model <|
        ThePage.view (Dev.makeCtx model)
