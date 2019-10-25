module Misc.Ui exposing (..)

import Element exposing (Element, padding, rgba)
import Element.Background as Bg
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Misc exposing (either)
import Misc.Colors as Colors exposing (white)


styledButton : List (Element.Attribute msg) -> { onPress : Maybe msg, label : Element msg } -> Element msg
styledButton attrs opts =
    let
        disabled =
            opts.onPress == Nothing

        enabled =
            not disabled

        allAttrs =
            List.append
                [ enabled |> either Colors.blue700 Colors.blue100 |> Bg.color
                , enabled |> either defaultShadow noShadow
                , Font.color white
                , Font.size 14
                , padding 5
                , Border.rounded 3
                ]
                attrs
    in
    Input.button allAttrs opts


noShadow =
    Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = rgba 0 0 0 0 }


defaultShadow =
    Border.shadow { offset = ( 1, 2 ), size = 1, blur = 7, color = rgba 0 0 0 0.2 }
