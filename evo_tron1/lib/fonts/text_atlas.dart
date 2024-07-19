// Collects static text textures
import 'dart:ffi';

import 'package:evo_tron1/gui/colors.dart';
import 'package:sdl2/sdl2.dart';

import 'raster/ttf_font.dart';
import 'text.dart';

class TextAtlas {
  static int pointSize = 15;

  late TTFont ttf;

  List<Text> texts = [];

  int initialize(Pointer<SdlRenderer> renderer) {
    ttf = TTFont(renderer);
    ttf.initialize();

    int fontStatus =
        ttf.load('evo_tron1/assets/', 'neuropol x rg.ttf', pointSize);
    if (fontStatus < 0) {
      return fontStatus;
    }

    return 0;
  }

  int addText(String text, double left, double top) {
    Pointer<SdlTexture>? texture =
        ttf.generateText(text, Colors().whiteC, Colors().blackC);
    if (texture == null) {
      return -1;
    }

    Text t = Text(texture)
      ..textWidth = ttf.textWidth
      ..textHeight = ttf.textHeight
      ..posTextRect = ttf.createPosRectangle(left, top)
      ..text = text;

    texts.add(t);
    return 0;
  }

  Text findText(String txt) {
    return texts.firstWhere(
      (text) => text.text == txt,
      orElse: () => Text.nil(),
    );
  }

  void setPosition(String text, double left, double top) {
    Text t = findText(text);
    if (!t.isNil) {
      setPositionByText(t, left, top);
    }
  }

  void setPositionByText(Text text, double left, double top) {
    text.left = left;
    text.top = top;
  }

  void drawInt(
    int value,
    double left,
    double top,
    double charWidth,
    Pointer<SdlRenderer> renderer,
  ) {
    String sv = '$value';
    List<String> ls = sv.split('');
    for (var char in ls) {
      Text txt = findText(char);
      txt.setPosition(left, top);
      left += charWidth;
      txt.draw(renderer);
    }
  }

  void destroy() {
    for (var texture in texts) {
      texture.destroy();
    }
    ttf.destroy();
  }
}
