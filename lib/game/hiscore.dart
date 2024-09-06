import 'package:flame/components.dart';

import 'game_data.dart';
import 'storage.dart';

final hiscore = Hiscore();

class Hiscore extends Component with HasGameData {
  static const int max_name_length = 10;
  static const int number_of_entries = 10;

  final entries = List.generate(number_of_entries, _defaultRank);

  HiscoreRank? latestRank;

  static HiscoreRank _defaultRank(int idx) => HiscoreRank(100000 - idx * 10000, 10 - idx, 'INTENSICODE');

  bool isNewHiscore(int score) => score > entries.first.score;

  bool isHiscoreRank(int score) => score > entries.last.score;

  int rank(int score) => entries.indexWhere((it) => it.score < score) + 1;

  void insert(int score, int level, String name) {
    final rank = HiscoreRank(score, level, name);
    for (int idx = 0; idx < entries.length; idx++) {
      final check = entries[idx];
      if (score <= check.score) continue;
      if (check == rank) break;
      entries.insert(idx, rank);
      entries.removeLast();
      break;
    }
    latestRank = rank;

    save('hiscore', this);
  }

  // Component

  @override
  onLoad() async => await load('hiscore', this);

  // HasGameData

  @override
  void load_state(GameData data) {
    entries.clear();

    final it = data['entries'] as List<dynamic>;
    entries.addAll(it.map((it) => HiscoreRank.load(it)));
  }

  @override
  GameData save_state(GameData data) => data..['entries'] = entries.map((it) => it.save_state({})).toList();
}

class HiscoreRank {
  final int score;
  final int level;
  final String name;

  HiscoreRank(this.score, this.level, this.name);

  HiscoreRank.load(GameData data) : this(data['score'], data['level'], data['name']);

  GameData save_state(GameData data) => data
    ..['score'] = score
    ..['level'] = level
    ..['name'] = name;
}
