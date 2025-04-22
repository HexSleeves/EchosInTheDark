(* Screen interface for all UI/game screens *)
module type Screen = sig
  type t

  val handle_tick : t -> State.t -> State.t * t
  val render : t -> State.t -> (t * State.t) option
end

module MainMenuScreen = struct
  open State

  type t = Mainmenu.t

  let handle_tick m s =
    let new_mainmenu, result = Mainmenu.handle_tick m in
    match result with
    | Some Play -> ({ s with screen = Playing }, new_mainmenu)
    | Some Quit ->
        ( { s with quitting = true; screen = MainMenu new_mainmenu },
          new_mainmenu )
    | None -> ({ s with screen = MainMenu new_mainmenu }, new_mainmenu)

  let render m s =
    match Mainmenu.render m with
    | Some m' -> Some (m', { s with screen = MainMenu m' })
    | None -> None
end

module PlayScreen = struct
  type t = State.t

  let handle_tick _ s = (Play.handle_tick s, s)

  let render _ s =
    match Play.render s with Some s' -> Some (s', s') | None -> None
end
