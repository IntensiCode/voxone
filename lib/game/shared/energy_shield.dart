import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/traits.dart';

class EnergyShield implements Target {
  EnergyShield(this._target, this._on_hit, this._rumble);

  final Target _target;
  final void Function() _on_hit;
  final void Function() _rumble;

  double _energy = 1;

  double get energy => _energy;

  void recharge(double amount) => _energy = min(1, _energy + amount);

  double shield_boost = 1.0;

  void on_shield_boost() => shield_boost = min(2, shield_boost + 0.1);

  @override
  bool get susceptible => _energy > 0.1;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    if (_target case HasVisibility it) {
      if (!it.isVisible) return;
    }
    _on_hit();
    _energy -= damage / 25 / shield_boost;
    if (_energy < 0) {
      if (dev) logInfo('shield depleted: $_energy');

      final danger = switch (difficulty) {
        Difficulty.easy => 2,
        Difficulty.normal => 5,
        Difficulty.hard => 10,
      };

      final remaining = max(0.0, _energy.abs() - 5);
      _target.on_hit(damage: remaining * danger);

      _energy = max(-5, _energy / 10);

      _rumble();
      audio.play(Sound.emit, volume_factor: 0.25);
      audio.play(Sound.plasma, volume_factor: 0.25);
    } else if (damage >= 1) {
      audio.play(Sound.teleport, volume_factor: 0.25);
    }
  }
}
