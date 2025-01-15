import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/voxel/vox_io.dart';

Future<StackedEntity> vox(
  String name,
  Shadows shadows, {
  int dx = 0,
  int dy = 0,
  int dz = 0,
  List<int>? blurred_argb32,
}) {
  return game.assets.readBinaryFile('entities/$name.vox').then((it) {
    final voxels = read_vox(it);
    final image = vox_to_image(voxels, dx: dx, dy: dy, dz: dz, blurred_argb32: blurred_argb32);
    final entity = StackedEntity.sprite(Sprite(image), voxels.height, shadows);
    entity.size.x = voxels.width.toDouble();
    entity.size.y = voxels.height.toDouble();
    return entity;
  });
}
