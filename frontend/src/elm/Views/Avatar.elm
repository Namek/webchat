module Views.Avatar exposing (renderAvatar)

import Html exposing (Html)
import Misc exposing (either)
import PseudoRandom
import Svg
import Svg.Attributes exposing (..)


{-| Randomizes a color in text format like `rgb(0,255,0)` based on seed and modifier.
-}
randColorStr seed modifier =
    let
        numbers =
            PseudoRandom.integerSequence 3 (seed + modifier)

        stringifiedNumbers =
            numbers |> List.map (modBy 256 >> String.fromInt)
    in
    "rgb(" ++ (String.join "," <| stringifiedNumbers) ++ ")"


scale : Int -> Int -> Int -> Int
scale min max randomizedNumber =
    let
        rangeSmall =
            max - min |> toFloat

        x =
            (randomizedNumber |> toFloat) / (PseudoRandom.m0 |> toFloat)
    in
    min + (rangeSmall * x |> truncate)


randNum : Int -> Int -> Int -> Int -> Int
randNum seed modifier min max =
    case PseudoRandom.integerSequence 1 (seed + modifier) of
        x :: _ ->
            scale min max x

        _ ->
            (max - min) // 2


renderAvatar : Int -> Html msg
renderAvatar unsafeSeed =
    let
        seed =
            if unsafeSeed == 0 then
                1337

            else
                unsafeSeed

        color =
            randColorStr seed

        num modifier min max =
            randNum seed modifier min max

        str =
            String.fromInt

        numStr modifier min max =
            str <| num modifier min max

        genRect m =
            Svg.rect
                [ x <| numStr (m + 23) 0 95
                , y <| numStr (m + 17) 0 90
                , width <| numStr (m + 25) 0 90
                , height <| numStr (m + 29) 0 90
                , fill <| color (m + 18)
                , transform <|
                    "rotate("
                        ++ numStr (m + 1234) -180 180
                        ++ " "
                        ++ numStr (m + 134) -10 50
                        ++ " "
                        ++ numStr (m + 134) 0 50
                        ++ ")"
                ]
                []

        genCircle m =
            Svg.circle
                [ cx <| numStr (m + 7534) 20 80
                , cy <| numStr (m + 213123) 20 80
                , r <| numStr (m + 1251) 10 34
                , stroke <| color (m + 756)
                , strokeWidth <| numStr (m + 123) 0 2
                , strokeLinecap "round"
                , fill <| color (m + 754)
                , transform <|
                    "rotate("
                        ++ numStr (m + 1234) -180 180
                        ++ " "
                        ++ numStr (m + 134) -10 50
                        ++ " "
                        ++ numStr (m + 134) 0 50
                        ++ ")"
                ]
                []
    in
    Svg.svg
        [ width "40"
        , height "40"
        , viewBox "0 0 100 100"
        , clipPath "url(#cut-to-circle)"
        ]
        (List.concat
            [ [ Svg.defs []
                    [ Svg.clipPath [ id "cut-to-circle" ]
                        [ Svg.circle [ cx "20", cy "20", r "20" ] [] ]
                    , Svg.filter [ id "blur" ]
                        [ Svg.feGaussianBlur [ in_ "SourceGraphic", stdDeviation "2" ] [] ]
                    ]
              , Svg.circle
                    [ cx "50", cy "50", r "47", fill <| color 17 ]
                    []
              ]
            , List.range 0 (num 379 5 10) |> List.map genRect
            , List.range 0 (num 523 4 10) |> List.map genCircle
            , List.range 0 (num 379 5 10) |> List.map genRect
            , List.range 0 (num 523 4 10) |> List.map genCircle
            , [ Svg.circle
                    [ cx "50"
                    , cy "50"
                    , r "50"
                    , stroke <| color 19443
                    , strokeWidth <| numStr 513 6 12
                    , strokeLinecap "round"
                    , fill "transparent"
                    , filter "url(#blur)"
                    ]
                    []
              ]
            ]
        )
