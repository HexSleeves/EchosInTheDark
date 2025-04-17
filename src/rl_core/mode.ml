module CtrlMode = struct
  type t = Normal | WaitInput | Died of float
  (* [@@deriving yojson] *)
end
