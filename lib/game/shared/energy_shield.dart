import 'dart:math';

import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/traits.dart';

class EnergyShield extends Trait implements Target {
  EnergyShield(super.self, this._target, this._on_hit);

  final Target _target;
  final void Function() _on_hit;

  double energy = 1;

  @override
  bool get susceptible => energy > 0.1;

  @override
  void on_hit([double damage = 1]) {
    _on_hit();
    energy -= damage / 25;
    if (energy < 0) {
      double remaining = energy.abs();
      if (remaining > 0) _target.on_hit(remaining * 25);
    }
    energy = max(0, energy);
    if (damage >= 1) {
      soundboard.play(Sound.teleport, volume_factor: 0.25);
    }
  }
}
