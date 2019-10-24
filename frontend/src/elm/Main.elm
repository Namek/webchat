module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Cmd.Extra
import Data.Chat exposing (ChatStateUpdate)
import Data.Context exposing (GlobalMsg(..))
import Data.Session exposing (Session, SessionState(..))
import Element exposing (Element, paragraph, text)
import Graphql.Document
import Graphql.Http
import Json.Decode
import Misc exposing (css, noCmd)
import Page exposing (Page(..), frame)
import Page.Chat as Chat
import Page.Errored as Errored exposing (PageLoadError(..))
import Page.Login as Login
import Ports exposing (ConnectionStatus(..), createSubscriptions, gotChatStateUpdate, socketStatusConnected, socketStatusReconnecting)
import RemoteData exposing (RemoteData)
import Request.Common exposing (sendMutationRequest, sendQueryRequest)
import Request.Message exposing (sub_chatStateUpdate)
import Request.Session exposing (LogInResult, LogOutResult, checkAuthSession, logOut)
import Route exposing (Route, modifyUrl)
import Task
import Time
import Url exposing (Url)



-- MAIN --


main : Program InitFlags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , subscriptions = subscriptions
        , update = update
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


type alias InitFlags =
    {}



-- STATE --


type alias Model =
    { navKey : Nav.Key
    , page : Page
    , lastLocation : Url
    , hideScrollbars : Bool
    , time : Time.Posix
    , timezone : Time.Zone
    , connectionStatus : ConnectionStatus
    , session : SessionState
    }


init : InitFlags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    {- check authorization before setting location from URL -}
    let
        model : Model
        model =
            { navKey = navKey
            , page = initialPage
            , lastLocation = url
            , hideScrollbars = False
            , session = GuestSession
            , time = Time.millisToPosix 0
            , timezone = Time.utc
            , connectionStatus = NotConnected
            }
    in
    ( model
    , Cmd.batch
        [ Cmd.Extra.perform CheckAuthSession
        , Task.perform SetTimezone Time.here
        , Task.perform SetTime Time.now
        ]
    )


initialPage : Page
initialPage =
    Blank



-- VIEW --


view : Model -> Document Msg
view model =
    let
        bodyAttrs =
            List.append
                [ css "max-height" "100vh" ]
                (if model.hideScrollbars then
                    [ css "overflow" "hidden", css "height" "100%", css "width" "100%" ]

                 else
                    []
                )
    in
    { title = "Webchat"
    , body =
        [ Element.layout bodyAttrs (model.page |> viewPage model)
        ]
    }


viewPage : Model -> Page -> Element Msg
viewPage model page =
    let
        isLoggedIn =
            model.session /= GuestSession

        frame =
            Page.frame HandleGlobalMsg isLoggedIn model.session

        getAuthorizedSession =
            \() ->
                case model.session of
                    LoggedSession session ->
                        session

                    _ ->
                        Debug.todo "you have to be authorized!"

        pageView =
            case page of
                Blank ->
                    paragraph [] [ text "" ]

                Errored subModel ->
                    Errored.view model.session subModel

                Login subModel ->
                    Login.view
                        { model = subModel
                        , lift = LoginMsg
                        , time = model.time
                        , timezone = model.timezone
                        }

                Chat subModel ->
                    Chat.view
                        { model = subModel
                        , lift = ChatMsg
                        , time = model.time
                        , timezone = model.timezone
                        , session = getAuthorizedSession ()
                        }
    in
    frame page pageView



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ gotChatStateUpdate GotWebSocketData
        , socketStatusConnected (NewWebSocketStatus Connected)
        , socketStatusReconnecting (NewWebSocketStatus Reconnecting)
        ]



-- UPDATE --


type Msg
    = SetTimezone Time.Zone
    | SetTime Time.Posix
    | NewWebSocketStatus ConnectionStatus ()
    | GotWebSocketData Json.Decode.Value
    | HandleGlobalMsg GlobalMsg
    | UrlChanged Url.Url
    | UrlRequested Browser.UrlRequest
    | CheckAuthSession
    | CheckAuthSession_Response (RemoteData (Graphql.Http.Error (Maybe LogInResult)) (Maybe LogInResult))
    | LogOut_Response (RemoteData (Graphql.Http.Error LogOutResult) LogOutResult)
    | LoginMsg Login.Msg
    | ChatMsg Chat.Msg


pageErrored : Model -> String -> ( Model, Cmd msg )
pageErrored model errorMessage =
    { model | page = Errored { errorMessage = errorMessage } }
        |> noCmd


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTimezone zone ->
            { model | timezone = zone } |> noCmd

        SetTime time ->
            { model | time = time } |> noCmd

        NewWebSocketStatus status () ->
            { model | connectionStatus = status } |> noCmd

        GotWebSocketData data ->
            case Json.Decode.decodeValue (sub_chatStateUpdate |> Graphql.Document.decoder) (Debug.log "data" data) of
                Ok stateUpdate ->
                    let
                        chatStateUpdate : ChatStateUpdate
                        chatStateUpdate =
                            stateUpdate
                    in
                    case model.page of
                        Chat pageModel ->
                            let
                                subModel =
                                    Chat.receiveChatStateUpdate pageModel chatStateUpdate
                            in
                            { model | page = Chat subModel } |> noCmd

                        _ ->
                            model |> noCmd

                Err error ->
                    -- TODO show error in top bar?
                    model |> noCmd

        HandleGlobalMsg globalMsg ->
            case globalMsg of
                Navigate route ->
                    ( model, Route.modifyUrl model route )

                SetSession (Just session) ->
                    { model | session = LoggedSession session } |> noCmd

                SetSession Nothing ->
                    -- TODO: logout
                    { model | session = GuestSession } |> noCmd

                SetScrollbarsVisibility visible ->
                    { model | hideScrollbars = not visible } |> noCmd

                RequestTimeUpdate ->
                    ( model, Task.perform SetTime Time.now )

        -- it's called when user first enters URL of website or back/forward is clicked
        UrlChanged url ->
            case Route.fromUrl url of
                Just route ->
                    initRoute (Just route) { model | lastLocation = url }

                _ ->
                    model |> noCmd

        UrlRequested req ->
            case req of
                Browser.Internal url ->
                    case Route.fromUrl url of
                        Just route ->
                            let
                                routeCmd =
                                    Route.modifyUrl model route
                            in
                            ( model, routeCmd )

                        Nothing ->
                            model |> noCmd

                Browser.External href ->
                    ( model, Nav.load href )

        CheckAuthSession ->
            let
                cmd =
                    checkAuthSession ()
                        |> sendQueryRequest CheckAuthSession_Response
            in
            ( model, cmd )

        {- Auth session is the first thing that comes from this app to backend - decides whether user is still logged in.
           Next thing is rerouting to the first page.
        -}
        CheckAuthSession_Response (RemoteData.Success maybeAuth) ->
            let
                ( newModel, cmds ) =
                    case maybeAuth of
                        Just result ->
                            let
                                modelWithSession =
                                    { model
                                        | session =
                                            LoggedSession
                                                { id = result.personId
                                                , name = result.personName
                                                }
                                    }
                            in
                            ( modelWithSession
                            , Route.modifyUrl model Route.Chat
                            )

                        Nothing ->
                            {- no valid token, guest session -}
                            ( { model | session = GuestSession }
                            , Route.modifyUrl model Route.Chat
                            )

                subscribeToChatUpdates =
                    createSubscriptions (sub_chatStateUpdate |> Graphql.Document.serializeSubscription)
            in
            ( newModel, Cmd.batch [ cmds, subscribeToChatUpdates ] )

        CheckAuthSession_Response (RemoteData.Failure err) ->
            {- we don't know but let's just say it's a guest session -}
            { model | session = GuestSession } |> noCmd

        CheckAuthSession_Response _ ->
            model |> noCmd

        LogOut_Response _ ->
            model |> noCmd

        _ ->
            updatePage model.page msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        toPageWithGlobalMsgs pageModelHandler msgLifter subUpdate subMsg =
            let
                ( ( pageModel, cmd ), globalMsg ) =
                    subUpdate subMsg

                cmds =
                    Cmd.batch
                        [ Cmd.map msgLifter cmd
                        , Cmd.map HandleGlobalMsg globalMsg
                        ]
            in
            ( { model | page = pageModelHandler pageModel }, cmds )

        buildCtx subModel lift session =
            { model = subModel
            , lift = lift
            , time = model.time
            , timezone = model.timezone
            , session = session
            }

        buildGuestCtx subModel lift =
            { model = subModel
            , lift = lift
            , time = model.time
            , timezone = model.timezone
            }
    in
    case ( msg, page, model.session ) of
        ( LoginMsg subMsg, Login subModel, GuestSession ) ->
            let
                ctx =
                    buildGuestCtx subModel LoginMsg
            in
            toPageWithGlobalMsgs Login LoginMsg (Login.update ctx) subMsg

        ( ChatMsg subMsg, Chat subModel, LoggedSession session ) ->
            let
                ctx =
                    buildCtx subModel ChatMsg session
            in
            toPageWithGlobalMsgs Chat ChatMsg (Chat.update ctx) subMsg

        ( _, _, _ ) ->
            -- Disregard incoming messages that arrived for the wrong page
            model |> noCmd



-- HELPERS --


{-| This does not change URL in a browser, it simply sets state in the model.
-}
initRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
initRoute maybeRoute model =
    let
        errored =
            pageErrored model

        whenLogged func =
            case model.session of
                LoggedSession session ->
                    func session

                GuestSession ->
                    initRoute (Just Route.Login) model

        initWhenLogged initFn pageStateHolder msgLift =
            whenLogged
                (\session ->
                    let
                        ( subModel, subMsg ) =
                            initFn session
                    in
                    ( { model | page = pageStateHolder <| subModel }
                    , Cmd.map msgLift subMsg
                    )
                )
    in
    case maybeRoute of
        Nothing ->
            ( { model | page = Errored <| { errorMessage = "Page was not found." } }
            , Cmd.none
            )

        Just Route.Login ->
            ( { model | page = Login Login.initialModel }
            , Cmd.none
            )

        Just Route.Logout ->
            ( { model | session = GuestSession }
            , Cmd.batch
                [ logOut () |> sendMutationRequest LogOut_Response
                , Route.modifyUrl model Route.Login
                ]
            )

        Just Route.Chat ->
            initWhenLogged Chat.init Page.Chat ChatMsg
