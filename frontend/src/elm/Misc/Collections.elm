module Misc.Collections exposing (..)

import Dict exposing (Dict)


fromListBy : (v -> comparable) -> List v -> Dict comparable v
fromListBy keyfn xs =
    List.foldl
        (\x acc -> Dict.insert (keyfn x) x acc)
        Dict.empty
        xs
