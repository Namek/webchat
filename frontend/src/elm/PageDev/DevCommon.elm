module PageDev.DevCommon exposing (Model, Msg(..), init, makeCtx, update, view)

import Data.CommonData exposing (CommonData)
import Data.Context exposing (GlobalMsg)
import Data.Session exposing (Session)
import Element exposing (Element, above, alignRight, centerX, clipY, column, fill, height, inFront, maximum, padding, paddingEach, scrollbarY, text, width)
import Element.Border as Border
import Html exposing (Html)
import Html.Attributes exposing (property)
import Json.Encode
import Misc exposing (css, datetimeStr, edges, monthToInt)
import Task
import Time exposing (Month(..))
import Time.Extra exposing (posixToParts)


type alias Model subModel =
    { subModel : subModel
    , time : Time.Posix
    , timezone : Time.Zone
    , session : Session
    , commonData : CommonData
    }


type Msg msg
    = GotPageMsg msg
    | GotGlobalCmd GlobalMsg
    | SetTimezone Time.Zone
    | SetTime Time.Posix


type alias Context subModel msg =
    { model : subModel
    , lift : msg -> Msg msg
    , time : Time.Posix
    , timezone : Time.Zone
    , session : Session
    , commonData : CommonData
    }


makeCtx : Model subModel -> Context subModel msg
makeCtx model =
    { model = model.subModel
    , lift = GotPageMsg
    , timezone = Time.utc
    , time = Time.millisToPosix 0
    , session = model.session
    , commonData = model.commonData
    }


init : (Session -> ( subModel, Cmd msg )) -> ( Model subModel, Cmd (Msg msg) )
init subInit =
    let
        session : Session
        session =
            { id = 1, email = "some3mail@test.com", name = "User" }

        ( subModel, subCmds ) =
            subInit session

        caughtCmds : Cmd (Msg msg)
        caughtCmds =
            Cmd.map (Debug.log "init" << GotPageMsg) <| subCmds

        commonData : CommonData
        commonData =
            {}

        model : Model subModel
        model =
            { subModel = subModel
            , time = Time.millisToPosix 0
            , timezone = Time.utc
            , session = session
            , commonData = commonData
            }

        getTimeCmd =
            Cmd.batch
                [ Task.perform SetTime Time.now
                , Task.perform SetTimezone Time.here
                ]
    in
    ( model, Cmd.batch [ getTimeCmd, caughtCmds ] )


update subUpdate handlePageMsg handleGlobalCmdMsg msg model =
    case msg of
        GotPageMsg pageMsg ->
            let
                dbg =
                    Debug.log "GotPageMsg" pageMsg
            in
            case handlePageMsg model pageMsg of
                Nothing ->
                    let
                        -- ctx : Context
                        ctx =
                            makeCtx model

                        ( ( newSubModel, localCmds ), globalCmds ) =
                            subUpdate ctx pageMsg
                    in
                    ( { model | subModel = newSubModel }
                    , Cmd.batch
                        [ Cmd.map (Debug.log "GotPageMsg: update" << GotPageMsg) <| localCmds
                        , Cmd.map (Debug.log "GotPageMsg: update" << GotGlobalCmd) <| globalCmds
                        ]
                    )

                Just ( model2, givenCmds ) ->
                    ( model2, givenCmds )

        GotGlobalCmd globalCmdMsg ->
            let
                dbg =
                    Debug.log "GotGlobalCmd: Msg" globalCmdMsg
            in
            case handleGlobalCmdMsg model globalCmdMsg of
                Just ( newModel, cmds ) ->
                    ( newModel, cmds )

                Nothing ->
                    ( model, Cmd.none )

        SetTimezone zone ->
            ( { model | timezone = zone }, Cmd.none )

        SetTime time ->
            ( { model | time = Debug.log "time" time }, Cmd.none )


view : Model subModel -> Element msg -> Html msg
view model content =
    let
        str =
            Json.Encode.string

        linkStylesheet href =
            Html.node "link" [ property "rel" (str "stylesheet"), property "href" (str href) ] []

        time =
            posixToParts model.timezone model.time
    in
    Element.layout [ css "max-height" "100vh" ] <|
        column
            [ width fill
            , height fill
            , inFront <|
                Element.el [ alignRight ] <|
                    text ("Debug time: " ++ datetimeStr time)
            ]
            [ Element.html <| linkStylesheet "/css/app.css"
            , Element.el [ centerX, width fill, height fill ] <| content
            ]
