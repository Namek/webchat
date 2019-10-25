module Page.Login exposing (Model, Msg, initialModel, update, view)

import Cmd.Extra
import Data.Context exposing (ContextData, GlobalMsg(..))
import Data.Session exposing (Session, SessionState(..))
import Element exposing (Element, alignRight, below, centerX, column, el, fill, link, moveDown, padding, paddingEach, paragraph, row, spacing, text, width)
import Element.Events exposing (onFocus, onLoseFocus)
import Element.Font as Font
import Element.Input as Input exposing (focusedOnLoad, placeholder)
import Graphql.Http as Http
import Html.Events
import Json.Decode as Json
import Misc exposing (attr, attrWhen, edges, viewIf)
import Misc.Colors as Colors
import Misc.Ui exposing (styledButton)
import RemoteData exposing (RemoteData)
import Request.Common exposing (..)
import Request.Session exposing (..)
import Route


type alias Model =
    { name : String
    , password : String
    , focusedField : Field
    , isLoading : Bool
    }


initialModel : Model
initialModel =
    { name = ""
    , password = ""
    , focusedField = None
    , isLoading = False
    }


type Msg
    = SetName String
    | SetPassword String
    | OnFieldFocused Field
    | OnFieldBlurred
    | OnInFormKeyDown Int
    | LogIn
    | LogIn_Response (RemoteData (Http.Error LogInResult) LogInResult)


type alias Context msg =
    ContextData Model Msg msg


update : Context msg -> Msg -> ( ( Model, Cmd Msg ), Cmd GlobalMsg )
update ctx msg =
    let
        { model } =
            ctx
    in
    case msg of
        SetName name ->
            ( ( { model | name = name }, Cmd.none ), Cmd.none )

        SetPassword password ->
            ( ( { model | password = password }, Cmd.none ), Cmd.none )

        OnFieldFocused field ->
            ( ( { model | focusedField = field }, Cmd.none ), Cmd.none )

        OnFieldBlurred ->
            ( ( { model | focusedField = None }, Cmd.none ), Cmd.none )

        OnInFormKeyDown keyCode ->
            let
                cmd =
                    if keyCode == 13 && isLoginFilled model then
                        Cmd.Extra.perform LogIn

                    else
                        Cmd.none
            in
            ( ( model, cmd ), Cmd.none )

        LogIn ->
            let
                cmd =
                    logIn model
                        |> sendMutationRequest LogIn_Response
            in
            ( ( { model | isLoading = True }, cmd ), Cmd.none )

        LogIn_Response res ->
            case res of
                RemoteData.Success logInResult ->
                    ( ( model, Cmd.none )
                    , Cmd.batch <|
                        List.map Cmd.Extra.perform
                            [ SetSession (Just { id = logInResult.personId, name = logInResult.personName })
                            , Navigate Route.Chat
                            ]
                    )

                _ ->
                    ( ( { model | isLoading = False }, Cmd.none ), Cmd.none )


view : Context msg -> Element msg
view ctx =
    let
        { lift, model } =
            ctx

        isPasswordTooShort =
            String.length model.password < minPasswordLength

        shouldErrorPassword =
            if String.isEmpty model.password || model.focusedField == Password then
                False

            else
                isPasswordTooShort

        formDisabled =
            model.isLoading
    in
    column
        [ padding 25
        , spacing 25
        , centerX
        , Element.inFront <|
            viewIf model.isLoading (paragraph [] [ text "Signing in..." ])
        ]
        [ paragraph
            [ Font.size 20 ]
            [ text "Hi. Log in or register." ]
        , column [ spacing 15 ]
            [ Input.text
                [ attr "name" "nickname"
                , focusedOnLoad
                , Element.htmlAttribute <| Html.Events.on "keydown" (Json.map (ctx.lift << OnInFormKeyDown) Html.Events.keyCode)
                , onFocus (lift <| OnFieldFocused Name)
                , onLoseFocus (lift <| OnFieldBlurred)
                , attr "disabled" "disabled" |> attrWhen formDisabled
                ]
                { onChange = lift << SetName
                , text = model.name
                , placeholder = Just <| placeholder [] <| text "Nickname"
                , label = Input.labelHidden "Nickname"
                }
            , Input.currentPassword
                [ Element.htmlAttribute <| Html.Events.on "keydown" (Json.map (ctx.lift << OnInFormKeyDown) Html.Events.keyCode)
                , viewInputError shouldErrorPassword <| "Minimum " ++ String.fromInt minPasswordLength ++ " characters"
                , onFocus (lift <| OnFieldFocused Password)
                , onLoseFocus (lift <| OnFieldBlurred)
                , attr "disabled" "disabled" |> attrWhen formDisabled
                ]
                { onChange = lift << SetPassword
                , text = model.password
                , placeholder = Just <| placeholder [] <| text "Password"
                , label = Input.labelHidden "Password"
                , show = False
                }
            ]
        , row [ width fill ]
            [ link []
                { url = Route.routeToString Route.Chat
                , label =
                    styledButton [ Font.size 20 ]
                        { onPress = Nothing
                        , label = text "↶ Cancel"
                        }
                }
            , styledButton [ Font.size 20, alignRight ]
                { onPress =
                    if (not <| isLoginFilled model) || formDisabled then
                        Nothing

                    else
                        Just (lift <| LogIn)
                , label =
                    row []
                        [ text "Log In"
                        , el [ Font.size 15, paddingEach { edges | left = 5 } ] <| text "👍"
                        ]
                }
            ]
        ]


viewInputError onCondition message =
    Element.el
        [ moveDown 5
        , Font.color Colors.red400
        , Font.size 12
        ]
        (text message)
        |> below
        |> attrWhen onCondition



-- VALIDATION --


minPasswordLength : number
minPasswordLength =
    7


isLoginFilled : Model -> Bool
isLoginFilled model =
    (&&)
        (String.length model.name > 3)
        (String.length model.password >= minPasswordLength)


type Field
    = None
    | Name
    | Password
