open Ppx_yojson_conv_lib.Yojson_conv

type stats = {
  max_hp : int;
  hp : int;
  attack : int;
  defense : int;
  speed : int;
}
[@@deriving yojson]
