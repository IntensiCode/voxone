import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/util/bitmap_font.dart';

const textColor = Color(0xFFffcc80);
const successColor = Color(0xFF20ff10);
const errorColor = Color(0xFFff2010);

late BitmapFont fancy_font;
late BitmapFont menu_font;
late BitmapFont mini_font;
late BitmapFont tiny_font;

loadFonts(AssetsCache assets) async {
  fancy_font = await BitmapFont.loadDst(
    images,
    assets,
    'fonts/font_fancy.png',
    columns: 16,
    rows: 8,
  );
  menu_font = await BitmapFont.loadDst(
    images,
    assets,
    'fonts/font_menu.png',
    columns: 16,
    rows: 8,
  );
  mini_font = await BitmapFont.loadDst(
    images,
    assets,
    'fonts/font_mini.png',
    columns: 16,
    rows: 8,
  );
  tiny_font = await BitmapFont.loadDst(
    images,
    assets,
    'fonts/font_tiny.png',
    columns: 16,
    rows: 8,
  );
}
