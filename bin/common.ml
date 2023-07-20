open Notty

(* U+25CF BLACK CIRCLE *)
let dot color = I.string (A.fg color) "●"

(* U+25AA BLACK SMALL SQUARE *)
let square color = I.string (A.fg color) "▪"

(** A few images used in several places. *)
module Images = struct
  (* let rec sierp c n =
     I.(
       if n > 1 then
         let ss = sierp c (pred n) in
         ss <-> (ss <|> ss)
       else hpad 1 0 (dot c)) *)

  let grid xxs = xxs |> List.map I.hcat |> I.vcat

  let outline attr i =
    let w, h = I.(width i, height i) in
    let chr x = I.uchar attr (Uchar.of_int x) 1 1
    and hbar = I.uchar attr (Uchar.of_int 0x2500) w 1
    and vbar = I.uchar attr (Uchar.of_int 0x2502) 1 h in
    let a, b, c, d = (chr 0x256d, chr 0x256e, chr 0x256f, chr 0x2570) in
    grid [ [ a; hbar; b ]; [ vbar; i; vbar ]; [ d; hbar; c ] ]
end
