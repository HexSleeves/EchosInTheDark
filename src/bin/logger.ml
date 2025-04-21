let src = Logs.Src.create "rl2025" ~doc:"Rougelike Tutorial 2025"

module Log = (val Logs.src_log src : Logs.LOG)

let setup_logger (level : Logs.level) =
  (* Custom reporter to include log source name in each log line *)
  let string_of_level = function
    | Logs.App -> "APP"
    | Logs.Error -> "ERROR"
    | Logs.Warning -> "WARN"
    | Logs.Info -> "INFO"
    | Logs.Debug -> "DEBUG"
  in

  let reporter : Logs.reporter =
    let report src level ~over k msgf =
      let k _ =
        over ();
        k ()
      in
      let module_name = Logs.Src.name src in
      msgf @@ fun ?header:_ ?tags:_ fmt ->
      Format.kfprintf k Format.std_formatter
        ("[%s][%s] @[" ^^ fmt ^^ "@]@.")
        (string_of_level level) module_name
    in
    { Logs.report }
  in

  Logs.set_reporter reporter;
  Logs.set_level (Some level)
