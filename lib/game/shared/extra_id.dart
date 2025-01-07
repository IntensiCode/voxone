enum ExtraId {
  triple_plasma(8, probability: 0.1),
  // acid_blast(9, random: 0.1),
  // ion_pulse(10, random: 0.1),
  // phosphor_swirl(11, random: 0.1),
  // yin_yang(12, random: 0.1),
  // plasma_ring(13, random: 0.1),
  // cluster_bomb(14, random: 0.1),
  // nuke_missile(15, random: 0.1),
  integrity(16, probability: 3),
  shield(17, probability: 1),
  // health3(18, random: 1),
  full_integrity(19, probability: 0.1),
  // full_shield(20, probability: 0.1),
  // full_weapon(21, random: 0.1),
  // full_clear(22, random: 0.1),
  // half_clear(23, random: 0.1),
  ;

  final int sheet_index;
  final double probability;

  const ExtraId(this.sheet_index, {this.probability = 0});

  static final restore = {integrity, shield, full_integrity};
  static final stage1_weapon = {triple_plasma};
}
