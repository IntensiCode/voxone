enum ExtraId {
  /// Primary weapon: Plasma gun with spread shot
  plasma_gun(8, probability: 0.1),

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
  integrity(16, probability: 1.6),

  /// Restore some shield energy
  shield(17, probability: 0.8),

  /// Cool down secondary weapon
  cooldown(18, probability: 0.8),

  /// Restore full integrity
  integrity_boost(19, probability: 0.2),

  /// Restore full shield energy
  shield_boost(20, probability: 0.2),

  /// Fully cool down secondary weapon
  cooldown_boost(21, probability: 0.2),

  /// Secondary weapon: Smart Bomb
  smart_bomb(22, probability: 0.05),
  ;

  final int sheet_index;
  final double probability;

  const ExtraId(this.sheet_index, {this.probability = 0});

  static final defaults = {
    plasma_gun,
    acid_blast,
    ion_pulse,
    phosphor_swirl,
    yin_yang,
    integrity,
    shield,
    cooldown,
    integrity_boost,
    shield_boost,
    cooldown_boost,
  };

  static final maintenance = {
    integrity,
    shield,
    cooldown,
    integrity_boost,
    shield_boost,
    cooldown_boost,
  };

  static final primaries = {
    plasma_gun,
    acid_blast,
    ion_pulse,
    phosphor_swirl,
    yin_yang,
  };

  static final secondaries = {
    plasma_ring,
    cluster_bomb,
    nuke_missile,
    smart_bomb,
  };
}
