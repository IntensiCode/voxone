enum GamePhase {
  confirm_exit,
  enter_round,
  game_complete,
  game_on,
  game_over,
  game_over_hiscore,
  game_paused,
  next_round,
  ;

  static GamePhase from(final String name) => GamePhase.values.firstWhere((e) => e.name == name);
}
