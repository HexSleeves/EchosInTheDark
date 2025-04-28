type t = {
  debug : bool;
  player_id : Entities.Types.Entity.id;
  mode : Entities.Types.CtrlMode.t;
  entities : Entities.Entity_manager.t;
  actor_manager : Actors.Actor_manager.t;
  turn_queue : Turn_queue.t;
  map_manager : Map_manager.t;
}
