import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef Check = bool Function();
typedef Hook = void Function();

bool debug = kDebugMode;
bool dev = kDebugMode;

const tps = 60;

const double game_width = 320;
const double game_height = 240;
final Vector2 game_size = Vector2(game_width, game_height);
final Vector2 game_center = game_size / 2;

const default_line_height = 12.0;
const debug_height = default_line_height;

const center_x = game_width / 2;
const center_y = game_height / 2;

const card_width = 72;
const card_height = 92;
const stack_card_offset = 1.0;

const game_left = 10.0;
const game_top = 10;

final stack_gap = Vector2(5, 20);
final ace_stacks_offset = Vector2(game_left, 40);
final play_stacks_offset = Vector2(game_left, 400);
final board_stack_offset = Vector2(game_left, 160);

late FlameGame game;
late Images images;

// to avoid importing materials elsewhere (which causes clashes sometimes), some color values right here

const minden_green = Color(0xFF007000);

const black = Colors.black;
const blue = Colors.blue;
const green = Colors.green;
const orange = Colors.orange;
const red = Colors.red;
const shadow = Color(0x80000000);
const shadow_dark = Color(0xC0000000);
const shadow_soft = Color(0x40000000);
const transparent = Colors.transparent;
const white = Colors.white;
const yellow = Colors.yellow;

Paint pixel_paint() => Paint()
  ..isAntiAlias = false
  ..filterQuality = FilterQuality.none;

mixin Message {}

class MouseWheel with Message {
  final double direction;

  MouseWheel(this.direction);
}

TODO(String message) => throw UnimplementedError(message);
