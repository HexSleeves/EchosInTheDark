open Base

let table : (int, Types.Equipment.t) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id

let get_exn id =
  Option.value_exn (Hashtbl.find table id)
    ~message:(Printf.sprintf "No equipment for entity id %d" id)

let set id equipment = Hashtbl.set table ~key:id ~data:equipment
let remove id = Hashtbl.remove table id
