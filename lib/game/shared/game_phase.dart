enum GamePhase {
  show_stage,
  intro,
  playing,
  complete,
  game_over,
  transition,
  ;

  static GamePhase from(final String name) => GamePhase.values.firstWhere((e) => e.name == name);
}
