open Ppx_yojson_conv_lib.Yojson_conv

module CtrlMode = struct
  type t = Normal | WaitInput | Died of float
  (* [@@deriving yojson] *)
end
