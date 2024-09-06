import 'dart:math';

import 'package:collection/collection.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/game_messages.dart';
import 'package:voxone/game/level/level_object.dart';
import 'package:voxone/game/level/micro_star_finder.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/on_message.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class PathFinder extends Component with AutoDispose {
  static const tile_size = 16.0;
  static const grid_size = 8.0;
  static const half_size = grid_size / 2;

  late MicroStarFinder _finder;

  final _pending = <(LevelProp, List<Vector2>)>[];

  (LevelProp, List<Vector2>)? _active;

  var _snapshot = <LevelObject>{};

  final _blocked = pixel_paint()..color = shadow;
  final _free = pixel_paint()..color = shadow_soft;
  final _path = pixel_paint()..color = red;
  final _edge = pixel_paint()..color = blue;

  final _temp_rect = MutableRectangle<double>(0, 0, 0, 0);

  @override
  void onMount() {
    super.onMount();
    onMessage<LevelDataAvailable>((it) => _init(it.map));
  }

  double _to_x(int col) => col * grid_size + half_size;

  double _to_y(int row) => game_height - grid_size - row * grid_size + half_size;

  int _to_col(double x) => x ~/ grid_size;

  int _to_row(double y) => (game_height - grid_size + half_size - y) ~/ grid_size;

  void _init(TiledMap map) {
    Object? blocker(MicroStarFinder it, int col, int row) {
      if (col == 0) return false;
      _temp_rect.left = _to_x(col) - half_size + 0.5;
      _temp_rect.top = _to_y(row) - half_size + 0.5;
      _temp_rect.width = grid_size - 1;
      _temp_rect.height = grid_size - 1;
      return _snapshot.firstWhereOrNull((it) => it.is_blocked_for_walking(_temp_rect));
    }

    int score(MicroStarFinder it, int col, int row, dynamic data) => 0;

    final cols = map.width * tile_size ~/ grid_size;
    final rows = map.height * tile_size ~/ grid_size;
    _finder = MicroStarFinder(cols, rows, blocker, score, map);
  }

  void find_path_to_player(LevelProp from, List<Vector2> out_segment) {
    logInfo('find path');
    if (_pending.any((it) => identical(it.$2, out_segment))) {
      logWarn('ignore duplicate find request');
      return;
    }
    _pending.add((from, out_segment));
    logInfo('pending size: ${_pending.length}');
  }

  @override
  void update(double dt) {
    if (_active == null && _pending.isNotEmpty) {
      _prepare_next_find();
    }

    final it = _active;
    if (it != null) _proceed(it.$2);
  }

  void _prepare_next_find() {
    final (from, _) = _active = _pending.first;

    timed('init finder', () {
      _finder.subject = from;
      _finder.reset();
      _update_for(from);
      _finder.set_start(_to_col(from.x), _to_row(from.y - half_size));
      _finder.set_end(_to_col(player.position.x), _to_row(player.position.y));
      _finder.begin();
    });
  }

  void _update_for(LevelObject it) {
    _snapshot = entities.obstacles.toSet();

    final x1 = _to_col(it.x);
    final y1 = _to_row(it.y);
    final x2 = _to_col(player.x);
    final y2 = _to_row(player.y);
    final left = min(x1, x2) - 5;
    final top = min(y1, y2) - 5;
    final right = max(x1, x2) + 5;
    final bottom = max(y1, y2) + 5;

    removeAll(children);
    _finder.update(left, top, right, bottom, (x, y, blocked) {
      if (blocked) {
        add(CircleComponent(
          radius: half_size,
          position: Vector2(_to_x(x), _to_y(y)),
          anchor: Anchor.center,
          paint: _blocked,
        ));
      } else {
        add(CircleComponent(
          radius: half_size,
          position: Vector2(_to_x(x), _to_y(y)),
          anchor: Anchor.center,
          paint: _free,
        ));
      }
    });
  }

  void _proceed(List<Vector2> out_segment) {
    timed('find steps', () {
      while (_finder.find_step(null)) {}
    });

    _active = null;
    final removed = _pending.removeAt(0);
    if (!_finder.has_path) _pending.add(removed);

    if (_finder.has_path && _finder.path_len > 0) {
      for (var i = 0; i < min(out_segment.length, _finder.path_len); i++) {
        final index = _finder.path[_finder.path_len - 1 - i];
        out_segment[i].x = _to_x(index % _finder.cols);
        out_segment[i].y = _to_y(index ~/ _finder.cols);
      }

      for (final it in out_segment) {
        if (it.isZero()) continue;
        add(CircleComponent(
          radius: half_size,
          position: Vector2(it.x, it.y),
          anchor: Anchor.center,
          paint: _path,
        ));
      }

      add(CircleComponent(
        radius: half_size,
        position: Vector2(_to_x(_finder.start % _finder.cols), _to_y(_finder.start ~/ _finder.cols)),
        anchor: Anchor.center,
        paint: _edge,
      ));
      add(CircleComponent(
        radius: half_size,
        position: Vector2(_to_x(_finder.end % _finder.cols), _to_y(_finder.end ~/ _finder.cols)),
        anchor: Anchor.center,
        paint: _edge,
      ));
    }
  }
}

void timed(String hint, void Function() block) {
  final start = DateTime.timestamp().millisecondsSinceEpoch;
  block();
  final end = DateTime.timestamp().millisecondsSinceEpoch;
  if (end - start > 5) logInfo('$hint time: ${end - start} ms');
}
