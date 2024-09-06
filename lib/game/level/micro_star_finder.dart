/*
The code below is adapted from https://github.com/felselva/uastar

Copyright (C) 2017 Felipe Ferreira da Silva

This software is provided 'as-is', without any express or implied warranty. In
no event will the authors be held liable for any damages arising from the use of
this software.

Permission is granted to anyone to use this software for any purpose, including
commercial applications, and to alter it and redistribute it freely, subject to
the following restrictions:

  1. The origin of this software must not be misrepresented; you must not claim
     that you wrote the original software. If you use this software in a
     product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

import 'package:voxone/util/extensions.dart';
import 'package:dart_minilog/dart_minilog.dart';

class MicroStarFinder {
  static const PATH_FINDER_MASK_PASSABLE = 0x01;
  static const PATH_FINDER_MASK_OPEN = 0x02;
  static const PATH_FINDER_MASK_CLOSED = 0x04;
  static const PATH_FINDER_MASK_PATH = 0x08;

  final int cols;
  final int rows;
  final List<int> state;
  final List<int> parents;
  final List<int> g_score;
  final List<int> f_score;
  final List<Object?> blocker;
  final Object? Function(MicroStarFinder it, int col, int row) blocked_func;
  final int Function(MicroStarFinder it, int col, int row, dynamic data) score_func;
  final dynamic data;

  Object? subject;

  late int start;
  late int end;
  bool has_path = false;
  final List<int> path;
  late int path_len;

  MicroStarFinder(this.cols, this.rows, this.blocked_func, this.score_func, this.data)
      : state = List<int>.filled(cols * rows, 0),
        blocker = List<Object?>.filled(cols * rows, null),
        parents = List<int>.filled(cols * rows, 0),
        g_score = List<int>.filled(cols * rows, 0),
        f_score = List<int>.filled(cols * rows, 0),
        path = List<int>.filled(cols * rows, -1) {
    logInfo('grid size: $cols x $rows = ${cols * rows}');
  }

  void update(int col_from, int row_from, int col_to, int row_to, void Function(int, int, bool) on_blocked) {
    logInfo('update $col_from $row_from $col_to $row_to');
    for (int y = row_from; y < row_to; y++) {
      if (y < 0 || y >= rows) continue;
      for (int x = col_from; x < col_to; x++) {
        if (x < 0 || x >= cols) continue;
        final index = y * cols + x;
        final blocked = blocked_func(this, x, y);
        if (blocked == null) {
          state[index] |= PATH_FINDER_MASK_PASSABLE;
        } else {
          state[index] &= ~PATH_FINDER_MASK_PASSABLE;
        }
        blocker[index] = blocked;
        on_blocked(x, y, blocked != null);
      }
    }
  }

  void reset() {
    start = -1;
    end = -1;
    has_path = false;

    state.fill(0);
    parents.fill(0);
    g_score.fill(0);
    f_score.fill(0);
    path.fill(-1);
  }

  void set_start(int col, int row) => start = row.clamp(0, rows - 1) * cols + col.clamp(0, cols - 1);

  void set_end(int col, int row) => end = row.clamp(0, rows - 1) * cols + col.clamp(0, cols - 1);

  void find(dynamic data) {
    begin();
    while (find_step(data)) {}
  }

  void begin() => state[start] = PATH_FINDER_MASK_PASSABLE | PATH_FINDER_MASK_OPEN;

  final _neighbors = List.filled(4, -1);

  bool find_step(dynamic data) {
    final count = cols * rows;
    int current = _lowest_in_open_set();
    bool run = true;
    if (current == end) {
      _reconstruct_path();
      run = false;
      has_path = true;
    } else if (_open_set_is_empty()) {
      run = false;
      has_path = false;
    } else {
      state[current] = state[current] & ~PATH_FINDER_MASK_OPEN;
      state[current] = state[current] | PATH_FINDER_MASK_CLOSED;
      _neighbors[0] = current % cols == 0 ? -1 : current - 1;
      _neighbors[1] = current < cols ? -1 : current - cols;
      _neighbors[2] = current % cols == cols - 1 ? -1 : current + 1;
      _neighbors[3] = current >= count - cols ? -1 : current + cols;
      int tmp_g_score = 0;
      for (int i = 0; i < 4; i++) {
        final n = _neighbors[i];
        if (n == -1) continue;
        if ((state[n] & PATH_FINDER_MASK_CLOSED) != 0) continue;
        if (blocker[n] != subject && state[n] & PATH_FINDER_MASK_PASSABLE == 0) {
          state[n] = state[n] | PATH_FINDER_MASK_CLOSED;
        } else {
          tmp_g_score = g_score[current] + 1;
          if ((state[n] & PATH_FINDER_MASK_OPEN) == 0 || tmp_g_score < g_score[n]) {
            parents[n] = current;
            g_score[n] = tmp_g_score;
            f_score[n] = tmp_g_score + _heuristic(n);
            f_score[n] += score_func(this, n % cols, n ~/ cols, data);
            state[n] = state[n] | PATH_FINDER_MASK_OPEN;
          }
        }
      }
    }
    return run;
  }

  void _reconstruct_path() {
    int i = end;
    var next = 0;
    while (i != start) {
      path[next++] = i;
      final p = parents[i];
      if (p != start) {
        state[p] = state[p] | PATH_FINDER_MASK_PATH;
      }
      i = p;
    }
    path_len = next;
  }

  int _lowest_in_open_set() {
    final count = cols * rows;
    var lowest_f = count;
    var current_lowest = -1;
    for (var i = 0; i < count; i++) {
      if ((state[i] & PATH_FINDER_MASK_OPEN) != 0) {
        final s = f_score[i];
        if (s < lowest_f) {
          lowest_f = s;
          current_lowest = i;
        }
      }
    }
    return current_lowest;
  }

  bool _open_set_is_empty() => !state.any((x) => (x & PATH_FINDER_MASK_OPEN) != 0);

  int _heuristic(int cell) {
    int cell_y = cell ~/ cols;
    int cell_x = cell % cols;
    int end_y = end ~/ cols;
    int end_x = end % cols;
    return (end_x - cell_x).abs() + (end_y - cell_y).abs();
  }
}
