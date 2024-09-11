class InputAcceleration {
  InputAcceleration({
    required bool Function() goNegative,
    required bool Function() goPositive,
    this.position = 0,
    this.velocity = 0,
    double velocityMax = 500,
    double acceleration = 500,
    double positionLimit = 160,
    double positionSoftBound = 32,
    double positionHardBound = 12,
  })  : _goPositive = goPositive,
        _goNegative = goNegative,
        _velocityMax = velocityMax,
        _acceleration = acceleration,
        _positionLimit = positionLimit,
        _softBound = positionSoftBound,
        _hardBound = positionHardBound;

  final bool Function() _goNegative;
  final bool Function() _goPositive;

  double position;
  double velocity;

  final double _velocityMax;
  final double _acceleration;
  final double _positionLimit;
  final double _softBound;
  final double _hardBound;

  var targetFrame = 0;

  void update(double dt) {
    targetFrame = 0;

    bool steered = false;

    final vxOld = velocity;
    if (_goNegative() && position > -_positionLimit + _softBound) {
      if (velocity > 0) {
        velocity *= 0.9;
      } else if (velocity.abs() > _velocityMax / 5) {
        targetFrame = -1;
      }
      velocity -= dt * _acceleration;
      steered = true;
    }
    if (_goPositive() && position < _positionLimit - _softBound) {
      if (velocity < 0) {
        velocity *= 0.9;
      } else if (velocity.abs() > _velocityMax / 5) {
        targetFrame = 1;
      }
      velocity += dt * _acceleration;
      steered = true;
    }
    if (!steered) targetFrame = 0;

    if (velocity.abs() > _velocityMax) velocity = _velocityMax * velocity.sign;

    position += velocity * dt;
    if (position.abs() > _positionLimit - _hardBound) {
      position = (_positionLimit - _hardBound) * position.sign;
    } else if (position.abs() > _positionLimit - _softBound) {
      position = (position.abs() - dt * _velocityMax / 10) * position.sign;
    }

    if (velocity == vxOld) velocity *= 0.9;
    if (velocity.abs() < 0.1) velocity = 0;
  }
}
