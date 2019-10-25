module Misc exposing (..)

import Element exposing (Element)
import Html.Attributes
import Process
import Regex exposing (Regex)
import Task
import Time exposing (Month(..))
import Time.Extra exposing (Interval(..))


noCmd : model -> ( model, Cmd msg )
noCmd model =
    ( model, Cmd.none )


viewIf : Bool -> Element msg -> Element msg
viewIf cond el =
    if cond then
        el

    else
        Element.none


either : a -> a -> Bool -> a
either a1 a2 cond =
    if cond then
        a1

    else
        a2


css property value =
    Element.htmlAttribute (Html.Attributes.style property value)


attr : String -> String -> Element.Attribute msg
attr name value =
    Element.htmlAttribute (Html.Attributes.attribute name value)


attrWhen : Bool -> Element.Attribute msg -> Element.Attribute msg
attrWhen condition otherAttr =
    if condition then
        otherAttr

    else
        attr "empty-attr" ""


edges =
    { top = 0
    , right = 0
    , bottom = 0
    , left = 0
    }


performMsgWithDelay : Float -> msg -> Cmd msg
performMsgWithDelay milliseconds msg =
    Process.sleep milliseconds
        |> Task.perform (always msg)


timeRelativeString : Time.Zone -> Time.Posix -> Time.Posix -> String
timeRelativeString timezone now before =
    -- TODO use time-distance lib
    let
        minutesAgo =
            Time.Extra.diff Minute timezone before now |> String.fromInt
    in
    minutesAgo ++ " minutes ago"


monthToInt : Month -> Int
monthToInt m =
    case m of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


datetimeStr : Time.Extra.Parts -> String
datetimeStr time =
    String.join " "
        [ String.join "-" <|
            [ time.year |> String.fromInt
            , time.month |> (monthToInt >> String.fromInt >> String.padLeft 2 '0')
            , time.day |> (String.fromInt >> String.padLeft 2 '0')
            ]
        , String.join ":" <|
            List.map (String.fromInt >> String.padLeft 2 '0') [ time.hour, time.minute ]
        ]


match : Regex -> String -> Bool
match regex str =
    Regex.find regex str
        |> List.any (.match >> (==) str)


emailRegex : Regex
emailRegex =
    Regex.fromString ".{3,}@.{2,}"
        |> Maybe.withDefault Regex.never


urlRegex : Regex
urlRegex =
    Regex.fromString "https?:\\/\\/[^\\s]+"
        |> Maybe.withDefault Regex.never
