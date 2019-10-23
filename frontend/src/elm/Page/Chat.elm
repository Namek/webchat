module Page.Chat exposing (..)

import Cmd.Extra
import Data.Chat exposing (ChatMessage, People, Person, PersonId, minutesToPassToGroupMessage, personName)
import Data.CommonData exposing (CommonData)
import Data.Context exposing (ContextData, GlobalMsg, Logged)
import Data.Session exposing (Session)
import Dict
import Element exposing (Element, alignBottom, alignTop, clip, column, el, fill, height, maximum, padding, paddingEach, px, row, scrollbarY, spacing, spacingXY, text, width)
import Element.Font as Font
import Element.Input as Input exposing (labelHidden)
import Graphql.Http
import Html.Events
import Json.Decode as Json
import List.Extra
import Misc exposing (css, edges, noCmd, performMsgWithDelay, timeRelativeString)
import Misc.Colors as Colors
import RemoteData exposing (RemoteData)
import Time
import Time.Extra exposing (Interval(..), posixToParts)



-- MODEL --


type alias Model =
    { chatState : Maybe ChatState, inputText : String }


type alias ChatState =
    { people : People
    , messages : ChatMessages
    }


type alias ChatStateUpdate =
    { newPeople : People
    , newMessages : List ChatMessage
    }


init : Session -> ( Model, Cmd Msg )
init session =
    let
        state =
            { chatState = Nothing, inputText = "" }
    in
    ( state
    , performMsgWithDelay 1 <| UpdateChatStateSince (Time.millisToPosix 0)
    )


type alias Context msg =
    Logged (ContextData Model Msg msg)


{-| Chat Messages: Chronologically grouped by authors
-}
type alias ChatMessages =
    List AuthorMessages


type alias AuthorMessages =
    { authorId : PersonId, authorName : String, messages : List ChatMessage }


messageCount : ChatMessages -> Int
messageCount =
    List.foldl (\msgs acc -> acc + List.length msgs.messages) 0



-- STATE UPDATE --


type Msg
    = UpdateChatStateSince Time.Posix
    | UpdateChatStateSince_Response (RemoteData (Graphql.Http.Error ChatStateUpdate) ChatStateUpdate)
    | SetInputText String
    | OnInputTextKeyDown Int
    | SendMessage String
    | SendMessage_Response (RemoteData (Graphql.Http.Error ChatStateUpdate) ChatStateUpdate)


update : Context msg -> Msg -> ( ( Model, Cmd Msg ), Cmd GlobalMsg )
update { model } msg =
    let
        chatState =
            model.chatState
    in
    case msg of
        UpdateChatStateSince posix ->
            -- TODO make a graphql request
            model |> noCmd |> noCmd

        UpdateChatStateSince_Response maybeTheUpdate ->
            let
                newChatState =
                    maybeTheUpdate
                        |> RemoteData.map
                            (\theUpdate ->
                                Just <| mergeUpdateToChatState chatState theUpdate
                            )
                        -- TODO: show the error in modal or elsewhere, instead of returning old state
                        |> RemoteData.withDefault chatState
            in
            { model | chatState = newChatState } |> noCmd |> noCmd

        SetInputText text ->
            { model | inputText = text } |> noCmd |> noCmd

        OnInputTextKeyDown keyCode ->
            let
                ( newModel, cmd ) =
                    -- send message to the backend on ENTER key
                    if keyCode == 13 then
                        if (String.length <| String.trim model.inputText) > 0 then
                            ( { model | inputText = "" }
                            , Cmd.Extra.perform <| SendMessage model.inputText
                            )

                        else
                            ( model, Cmd.none )

                    else
                        ( model, Cmd.none )
            in
            ( newModel, cmd ) |> noCmd

        SendMessage text ->
            -- TODO graphql mutation
            model |> noCmd |> noCmd

        SendMessage_Response maybeTheUpdate ->
            let
                newChatState =
                    maybeTheUpdate
                        |> RemoteData.map
                            (\theUpdate ->
                                Just <| mergeUpdateToChatState chatState theUpdate
                            )
                        -- TODO: show the error in modal or elsewhere, instead of returning old state
                        |> RemoteData.withDefault chatState
            in
            { model | chatState = newChatState } |> noCmd |> noCmd


mergeUpdateToChatState : Maybe ChatState -> ChatStateUpdate -> ChatState
mergeUpdateToChatState currentState theUpdate =
    case currentState of
        Nothing ->
            let
                people =
                    theUpdate.newPeople
            in
            { people = people
            , messages = insertAndGroupMessages people [] theUpdate.newMessages
            }

        Just oldState ->
            let
                people =
                    Dict.union theUpdate.newPeople oldState.people

                messages =
                    insertAndGroupMessages people oldState.messages theUpdate.newMessages
            in
            { people = people
            , messages = messages
            }


{-| Assumption:
New messages are always put into the end of old state. New messages should be sorted by datetime ASC.
The only matter to solve is whether a new message group should be created or not.
-}
insertAndGroupMessages : People -> ChatMessages -> List ChatMessage -> ChatMessages
insertAndGroupMessages people oldState newMessages =
    List.foldl
        (\newMsg messageGroups ->
            let
                lastGroupSplitted =
                    List.Extra.unconsLast messageGroups

                shouldAddToLastGroup =
                    case lastGroupSplitted of
                        Nothing ->
                            False

                        Just ( lastGroup, _ ) ->
                            case ( newMsg.authorId == lastGroup.authorId, lastGroup.messages ) of
                                ( True, m :: _ ) ->
                                    let
                                        minutesDiff =
                                            Time.Extra.diff Minute Time.utc newMsg.datetime m.datetime
                                    in
                                    minutesToPassToGroupMessage > minutesDiff

                                _ ->
                                    False
            in
            case ( shouldAddToLastGroup, lastGroupSplitted ) of
                ( True, Just ( lastGroup, groupsWithoutLast ) ) ->
                    let
                        updatedLastGroup : AuthorMessages
                        updatedLastGroup =
                            { lastGroup | messages = List.append lastGroup.messages [ newMsg ] }
                    in
                    List.append groupsWithoutLast [ updatedLastGroup ]

                _ ->
                    let
                        newGroup : AuthorMessages
                        newGroup =
                            { authorId = newMsg.authorId
                            , authorName = personName newMsg.authorId people
                            , messages = [ newMsg ]
                            }
                    in
                    List.append messageGroups [ newGroup ]
        )
        oldState
        newMessages



-- VIEW --


view : Context msg -> Element msg
view ctx =
    let
        { model, time, timezone } =
            ctx
    in
    case model.chatState of
        Just chatState ->
            let
                groupedMsgs =
                    chatState.messages
            in
            column
                [ width fill
                , height fill
                , css "max-height" "100vh"
                , padding 10
                , clip
                , spacing 15
                ]
                [ column
                    [ width fill
                    , height fill
                    , spacingXY 0 14
                    , Font.size 16
                    , scrollbarY
                    ]
                  <|
                    (groupedMsgs |> List.map (renderMessageGroup time timezone chatState.people))
                , renderChatInput ctx
                ]

        Nothing ->
            text "Loading..."


renderMessageGroup : Time.Posix -> Time.Zone -> People -> AuthorMessages -> Element msg
renderMessageGroup time timezone people messageGroup =
    row [ width fill, spacing 20 ]
        [ el [ alignTop ] <| text "<AVATAR>"
        , column [ alignTop, spacing 7 ]
            (renderGroupHeader time timezone messageGroup
                :: (messageGroup.messages |> List.map renderMessage)
            )
        ]


renderGroupHeader : Time.Posix -> Time.Zone -> AuthorMessages -> Element msg
renderGroupHeader time timezone messageGroup =
    let
        datetimeStr =
            messageGroup.messages
                |> List.Extra.uncons
                |> Maybe.map (\( msg, _ ) -> msg.datetime)
                --                |> Maybe.map (timeRelativeString timezone time)
                |> Maybe.map
                    (\datetime ->
                        let
                            -- TODO use timezone here
                            t =
                                datetime |> posixToParts timezone
                        in
                        String.join ":"
                            [ t.hour |> String.fromInt |> String.padLeft 2 '0'
                            , t.minute |> String.fromInt |> String.padLeft 2 '0'
                            ]
                    )
                |> Maybe.withDefault ""
    in
    row [ spacing 14 ]
        [ el [ Font.bold ] <| text messageGroup.authorName
        , el [ Font.size 12, Font.color Colors.gray500, alignBottom, paddingEach { edges | bottom = 1 } ] <| text datetimeStr
        ]


renderMessage : ChatMessage -> Element msg
renderMessage msg =
    text msg.content


renderChatInput : Context msg -> Element msg
renderChatInput ctx =
    Input.text
        [ Element.htmlAttribute <| Html.Events.on "keydown" (Json.map (ctx.lift << OnInputTextKeyDown) Html.Events.keyCode)
        , alignBottom
        ]
        { onChange = SetInputText >> ctx.lift
        , text = ctx.model.inputText
        , label = labelHidden "Write on chat"
        , placeholder = Just <| Input.placeholder [] (text "Write on chat")
        }
