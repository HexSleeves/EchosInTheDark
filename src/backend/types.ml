open Ppx_yojson_conv_lib.Yojson_conv

type faction = int [@@deriving yojson]
type loc = int * int
