enum PlayerState {
  gone,
  entering,
  playing,
  leaving,
  dying,
  ;

  static PlayerState from(final String name) => PlayerState.values.firstWhere((e) => e.name == name);
}
