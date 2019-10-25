module Page.Chat exposing (..)

import Browser.Dom
import Cmd.Extra
import Data.Chat exposing (ChatMessage, ChatStateUpdate, MessageId, People, Person, PersonId, minutesToPassToGroupMessage, personName)
import Data.Context exposing (ContextData, GlobalMsg, Logged, MaybeLogged)
import Data.Session exposing (Session)
import Dict
import Element exposing (Element, alignBottom, alignTop, centerX, clip, column, el, fill, height, link, maximum, newTabLink, padding, paddingEach, px, row, scrollbarY, spacing, spacingXY, text, width)
import Element.Font as Font exposing (Font)
import Element.Input as Input exposing (labelHidden)
import Graphql.Http
import Html.Events
import Json.Decode as Json
import List.Extra
import Misc exposing (attr, css, edges, emailRegex, match, noCmd, performMsgWithDelay, timeRelativeString, urlRegex)
import Misc.Colors as Colors
import Regex exposing (Regex)
import RemoteData exposing (RemoteData)
import Request.Common exposing (sendMutationRequest, sendQueryRequest)
import Request.Message exposing (addMessage, getChatState)
import Route
import Task
import Time
import Time.Extra exposing (Interval(..), posixToParts)



-- MODEL --


type alias Model =
    { chatState : Maybe ChatState, inputText : String }


type alias ChatState =
    { people : People
    , messages : ChatMessages
    }


init : Maybe Session -> ( Model, Cmd Msg )
init session =
    let
        model =
            { chatState = Nothing, inputText = "" }
    in
    ( model
    , performMsgWithDelay 1 <| UpdateChatStateSince Nothing
    )


receiveChatStateUpdate : Model -> ChatStateUpdate -> ( Model, Cmd Msg )
receiveChatStateUpdate model chatStateUpdate =
    { model | chatState = Just <| mergeUpdateToChatState model.chatState chatStateUpdate }
        |> Cmd.Extra.with (jumpToBottom chatMessagesElementId)


type alias Context msg =
    MaybeLogged (ContextData Model Msg msg)


{-| Chat Messages: Chronologically grouped by authors
-}
type alias ChatMessages =
    List AuthorMessages


type alias AuthorMessages =
    { authorId : PersonId, authorName : String, messages : List RenderedChatMessage }


type alias RenderedChatMessage =
    { id : MessageId
    , content : List MessagePart
    , authorId : PersonId

    -- UTC time
    , datetime : Time.Posix
    }


type MessagePart
    = MsgText String
    | MsgLink String


countMessages : ChatMessages -> Int
countMessages =
    List.foldl (\msgs acc -> acc + List.length msgs.messages) 0



-- STATE UPDATE --


type Msg
    = UpdateChatStateSince (Maybe Time.Posix)
    | UpdateChatStateSince_Response (RemoteData (Graphql.Http.Error ChatStateUpdate) ChatStateUpdate)
    | SetInputText String
    | OnInputTextKeyDown Int
    | SendMessage String
    | SendMessage_Response (RemoteData (Graphql.Http.Error ()) ())
    | Jumped (Result Browser.Dom.Error ())


update : Context msg -> Msg -> ( ( Model, Cmd Msg ), Cmd GlobalMsg )
update { model } msg =
    let
        chatState =
            model.chatState
    in
    case msg of
        UpdateChatStateSince posix ->
            let
                queryCmd =
                    getChatState posix
                        |> sendQueryRequest UpdateChatStateSince_Response
            in
            ( model, queryCmd ) |> noCmd

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
            { model | chatState = newChatState }
                |> Cmd.Extra.with (jumpToBottom chatMessagesElementId)
                |> noCmd

        SetInputText text ->
            { model | inputText = text } |> noCmd |> noCmd

        OnInputTextKeyDown keyCode ->
            let
                ( newModel, cmd ) =
                    -- send message to the backend on ENTER key
                    if keyCode == 13 then
                        if (String.length <| String.trim model.inputText) > 0 then
                            ( model
                            , Cmd.Extra.perform <| SendMessage model.inputText
                            )

                        else
                            ( model, Cmd.none )

                    else
                        ( model, Cmd.none )
            in
            ( newModel, cmd ) |> noCmd

        SendMessage text ->
            let
                mutationCmd =
                    addMessage text
                        |> sendMutationRequest SendMessage_Response
            in
            model |> Cmd.Extra.with mutationCmd |> noCmd

        SendMessage_Response (RemoteData.Success _) ->
            { model | inputText = "" } |> noCmd |> noCmd

        SendMessage_Response _ ->
            model |> noCmd |> noCmd

        Jumped _ ->
            model |> noCmd |> noCmd


jumpToBottom id =
    Browser.Dom.setViewportOf id 0 100000
        |> Task.attempt Jumped



--            let
--                newChatState =
--                    maybeTheUpdate
--                        |> RemoteData.map
--                            (\theUpdate ->
--                                Just <| mergeUpdateToChatState chatState theUpdate
--                            )
--                        -- TODO: show the error in modal or elsewhere, instead of returning old state
--                        |> RemoteData.withDefault chatState
--            in
--            { model | chatState = newChatState } |> noCmd |> noCmd


mergeUpdateToChatState : Maybe ChatState -> ChatStateUpdate -> ChatState
mergeUpdateToChatState currentState theUpdate =
    case currentState of
        Nothing ->
            let
                people =
                    theUpdate.people
            in
            { people = people
            , messages = insertAndGroupMessages people [] theUpdate.newMessages
            }

        Just oldState ->
            let
                -- Note: some people may have disappeared from chat but we may
                -- still have old messages so let's not dump old peeps, for now.
                people =
                    Dict.union theUpdate.people oldState.people

                messages =
                    insertAndGroupMessages people oldState.messages theUpdate.newMessages
            in
            { people = people
            , messages = messages
            }


parseMessageContent : String -> List MessagePart
parseMessageContent content =
    let
        placesOfLinks =
            Regex.find urlRegex content
                |> List.map
                    (\match ->
                        ( ( match.index, String.length match.match ), MsgLink match.match )
                    )
                |> List.sortBy (\( ( index, length ), msgLink ) -> index)

        links : List MessagePart
        links =
            placesOfLinks
                |> List.map (\( ( index, length ), msgLink ) -> msgLink)

        texts : List MessagePart
        texts =
            Regex.split urlRegex content
                |> List.map MsgText

        zip =
            List.map2 (\a b -> [ a, b ])

        contentStartsWithLink =
            case placesOfLinks of
                ( ( index, _ ), _ ) :: _ ->
                    index == 0

                _ ->
                    False

        linksAndTextsZippedBack =
            -- we need a fix around List.map2 which drops last element if list lenghts are unequal
            let
                linksLen =
                    List.length links

                textsLen =
                    List.length texts

                links2 =
                    if linksLen < textsLen then
                        List.append links [ MsgText "" ]

                    else
                        links

                texts2 =
                    if linksLen > textsLen then
                        List.append texts [ MsgText "" ]

                    else
                        texts
            in
            if contentStartsWithLink then
                zip links2 texts2

            else
                zip texts2 links2
    in
    linksAndTextsZippedBack |> List.concat


{-| Assumption:
New messages are always put into the end of old state. New messages should be sorted by datetime ASC.
The only matter to solve is whether a new message group should be created or not.
-}
insertAndGroupMessages : People -> ChatMessages -> List ChatMessage -> ChatMessages
insertAndGroupMessages people oldState newMessages =
    let
        newMessagesParsed : List RenderedChatMessage
        newMessagesParsed =
            newMessages
                |> List.map
                    (\msg ->
                        { id = msg.id
                        , authorId = msg.authorId
                        , datetime = msg.datetime
                        , content = parseMessageContent msg.content
                        }
                    )
    in
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
        newMessagesParsed



-- VIEW --


chatMessagesElementId =
    "chat-messages-container"


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

                renderMessages =
                    case countMessages groupedMsgs of
                        0 ->
                            [ column [ centerX, paddingEach { edges | top = 20 } ]
                                [ text "Nothing's going on here. Invite your friends in your real life to chat here!"
                                , if ctx.session == Data.Session.GuestSession then
                                    row [ Font.size 25, paddingEach { edges | top = 40 }, centerX ]
                                        [ link []
                                            { url = Route.routeToString Route.Login
                                            , label = el [ Font.color Colors.blue500 ] <| text "Log in"
                                            }
                                        , text " to chat"
                                        ]

                                  else
                                    Element.none
                                ]
                            ]

                        _ ->
                            groupedMsgs |> List.map (renderMessageGroup time timezone chatState.people)
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
                    , attr "id" chatMessagesElementId
                    ]
                  <|
                    renderMessages
                , renderChatInput ctx
                ]

        Nothing ->
            el [ centerX ] <| text "Loading..."


renderMessageGroup : Time.Posix -> Time.Zone -> People -> AuthorMessages -> Element msg
renderMessageGroup time timezone people messageGroup =
    row [ width fill, spacing 20 ]
        [ el [ alignTop ] <| text ""
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


renderMessage : RenderedChatMessage -> Element msg
renderMessage msg =
    let
        renderPart : MessagePart -> Element msg
        renderPart part =
            case part of
                MsgText string ->
                    text string

                MsgLink string ->
                    newTabLink [ Font.color Colors.blue500 ] { url = string, label = text string }
    in
    msg.content |> List.map renderPart |> row []


renderChatInput : Context msg -> Element msg
renderChatInput ctx =
    case ctx.session of
        Data.Session.LoggedSession session ->
            Input.text
                [ Element.htmlAttribute <| Html.Events.on "keydown" (Json.map (ctx.lift << OnInputTextKeyDown) Html.Events.keyCode)
                , alignBottom
                ]
                { onChange = SetInputText >> ctx.lift
                , text = ctx.model.inputText
                , label = labelHidden "Write on chat"
                , placeholder = Just <| Input.placeholder [] (text "Write on chat")
                }

        Data.Session.GuestSession ->
            let
                messageCount =
                    ctx.model.chatState
                        |> Maybe.map (\s -> s.messages |> countMessages)
                        |> Maybe.withDefault 0
            in
            row [] <|
                case messageCount of
                    0 ->
                        -- the "Log in" link is displayed on the top, centered
                        []

                    _ ->
                        [ link []
                            { url = Route.routeToString Route.Login
                            , label = el [ Font.color Colors.blue500 ] <| text "Log in"
                            }
                        , text " to chat"
                        ]
