open Ppx_yojson_conv_lib.Yojson_conv

type loc = int * int [@@deriving yojson, show]
type direction = North | East | South | West [@@deriving yojson, show]
