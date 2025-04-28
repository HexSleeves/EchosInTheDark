open Base

let table : (int, Types.Loc.t) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id

let get_exn id =
  Option.value_exn (Hashtbl.find table id)
    ~message:(Printf.sprintf "No position for entity id %d" id)

let set id pos = Hashtbl.set table ~key:id ~data:pos
let remove id = Hashtbl.remove table id
