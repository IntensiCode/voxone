enum ExtraId {
  /// Primary weapon: Plasma gun with spread triple shot
  triple_plasma(8, probability: 0.1),

  /// Primary weapon: Widening acid blast
  acid_blast(9, probability: 0.1),

  /// Primary weapon: Pulsed energy blasts
  ion_pulse(10, probability: 0.1),

  /// Primary weapon: Penetrating energy swirl
  phosphor_swirl(11, probability: 0.1),

  /// Primary weapon: Yin-yang energy orbs bouncing between targets on impact
  yin_yang(12, probability: 0.1),

  /// Secondary weapon: Expanding plasma ring
  plasma_ring(13, probability: 0.1),

  /// Secondary weapon: Exploding into multiple bombs
  cluster_bomb(14, probability: 0.1),

  /// Secondary weapon: Nukes large area on impact
  nuke_missile(15, probability: 0.1),

  /// Restore some integrity
  integrity(16, probability: 10),

  /// Restore some shield energy
  shield(17, probability: 1),

  /// Cool down secondary weapon
  cooldown(18, probability: 1),

  /// Restore full integrity
  full_integrity(19, probability: 0.1),

  /// Restore full shield energy
  full_shield(20, probability: 0.1),

  /// Fully cool down secondary weapon
  full_cooldown(21, probability: 0.1),

  /// Secondary weapon: Super Strong Smart Bomb
  super_smart_bomb(22, probability: 0.1),

  /// Secondary weapon: Smart Bomb
  smart_bomb(23, probability: 0.1),
  ;

  final int sheet_index;
  final double probability;

  const ExtraId(this.sheet_index, {this.probability = 0});

  static final defaults = {
    triple_plasma,
    acid_blast,
    ion_pulse,
    phosphor_swirl,
    yin_yang,
    integrity,
    shield,
    cooldown,
    full_integrity,
    full_shield,
    full_cooldown,
  };
}
