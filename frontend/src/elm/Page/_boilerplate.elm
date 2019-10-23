module Page.Boilerplate exposing (Model, Msg, init, update, view)

import Cmd.Extra
import Data.Context exposing (ContextData, GlobalMsg, Logged)
import Data.Session exposing (Session)
import Element exposing (Element, column, row, text)



-- MODEL --


type alias Model =
    {}


init : Session -> ( Model, Cmd Msg )
init session =
    ( {}, Cmd.none )


type alias Context msg =
    Logged (ContextData Model Msg msg)



-- STATE UPDATE --


type Msg
    = Well


update : Context msg -> Msg -> ( ( Model, Cmd Msg ), Cmd GlobalMsg )
update { model } msg =
    ( ( model, Cmd.none ), Cmd.none )



-- VIEW --


view : Context msg -> Element msg
view { model } =
    row [] [ text "page" ]
