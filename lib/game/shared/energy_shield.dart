import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/traits.dart';

class EnergyShield extends Trait implements Target {
  EnergyShield(super.self, this._target, this._on_hit);

  final Target _target;
  final void Function() _on_hit;

  double _energy = 1;

  double get energy => _energy;

  void recharge(double amount) => _energy = min(1, _energy + amount);

  @override
  bool get susceptible => _energy > 0.1;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    _on_hit();
    _energy -= damage / 25;
    if (_energy < 0) {
      double remaining = _energy.abs();
      if (remaining > 0) _target.on_hit(damage: remaining * 25);
    }
    _energy = max(0, _energy);
    if (damage >= 1) {
      audio.play(Sound.teleport, volume_factor: 0.25);
    }
  }
}
