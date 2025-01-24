class Voxels {
  final int width;
  final int height;
  final int depth;
  final List<List<List<int>>> voxels; // y layers, z- then x-planes
  final List<int> palette;

  Voxels(this.width, this.height, this.depth, this.voxels, this.palette);

  Voxels remove_empty_ys_at_start_and_end() {
    var empty_below = voxels.indexWhere((layer) => layer.any((row) => row.any((v) => v != 0)));
    if (empty_below == -1) empty_below = 0;

    var empty_above = voxels.lastIndexWhere((layer) => layer.any((row) => row.any((v) => v != 0)));
    if (empty_above == -1) empty_above = voxels.length - 1;

    final it = voxels.skip(empty_below).take(empty_above - empty_below).toList(growable: false);
    return Voxels(width, it.length, depth, it, palette);
  }
}
