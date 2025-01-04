import 'package:voxone/game/context.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';

extension ContextExtensions on Context {
  MarauderMines get mines => model.mines;
}
