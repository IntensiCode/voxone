Function(Difficulty)? on_difficulty_change;

var _difficulty = Difficulty.normal;

Difficulty get difficulty => _difficulty;

set difficulty(Difficulty value) {
  _difficulty = value;
  on_difficulty_change?.call(value);
}

enum Difficulty {
  easy,
  normal,
  hard,
}
