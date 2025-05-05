open Components

(* Create profiling hooks for the Position component *)
let get id =
  Performance_profiler.time_component_lookup "Position" (fun () ->
      Position.get id)

let get_exn id =
  Performance_profiler.time_component_lookup "Position" (fun () ->
      Position.get_exn id)

let set id pos =
  Performance_profiler.time_component_lookup "Position" (fun () ->
      Position.set id pos)

let remove id =
  Performance_profiler.time_component_lookup "Position" (fun () ->
      Position.remove id)

(* Create profiling hooks for the Stats component *)
let get_stats id =
  Performance_profiler.time_component_lookup "Stats" (fun () -> Stats.get id)

let get_stats_exn id =
  Performance_profiler.time_component_lookup "Stats" (fun () ->
      Stats.get_exn id)

let set_stats id stats =
  Performance_profiler.time_component_lookup "Stats" (fun () ->
      Stats.set id stats)

(* Create profiling hooks for the Blocking component *)
let get_blocking id =
  Performance_profiler.time_component_lookup "Blocking" (fun () ->
      Blocking.get id)

let set_blocking id blocking =
  Performance_profiler.time_component_lookup "Blocking" (fun () ->
      Blocking.set id blocking)

(* Create profiling hooks for the Renderable component *)
let get_renderable id =
  Performance_profiler.time_component_lookup "Renderable" (fun () ->
      Renderable.get id)

let set_renderable id renderable =
  Performance_profiler.time_component_lookup "Renderable" (fun () ->
      Renderable.set id renderable)

let init () =
  (* We'll hook into the components in a minimally invasive way *)
  Core_log.info (fun m -> m "Initializing position profiler...")
