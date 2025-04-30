(* Main modules of game. They don't carry much state between them *)
type screen = MainMenu of Mainmenu.t | Playing | GameOver [@@deriving show]

(* Errors when updating or rendering a screen *)
type screen_update_error = StateUpdateError of string | RenderError of string
