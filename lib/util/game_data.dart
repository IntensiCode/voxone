typedef GameData = Map<String, dynamic>;

mixin HasGameData {
  void load_state(GameData data);

  GameData save_state(GameData data);
}
