// Collects static text textures
import 'dart:ffi';
import 'dart:math';

import 'package:evo_tron1/gui/colors.dart';
import 'package:sdl2/sdl2.dart';

import 'raster/ttf_font.dart';

class Text {
  final Pointer<SdlTexture> texture;
  double textWidth = 0;
  double textHeight = 0;
  double left = 0;
  double top = 0;
  late Rectangle<double> posTextRect;
  late String text;

  Text(this.texture);

  factory Text.nil() => Text(nullptr);

  bool get isNil => texture == nullptr;

  void draw(Pointer<SdlRenderer> renderer) {
    renderer.copy(texture, dstrect: posTextRect);
  }

  void destroy() {
    texture.destroy();
  }
}

class TextAtlas {
  late TTFont ttf;
  late Pointer<SdlRenderer> renderer;

  List<Text> texts = [];

  int initialize(Pointer<SdlRenderer> renderer) {
    this.renderer = renderer;
    ttf = TTFont(renderer);
    ttf.initialize();

    int fontStatus = ttf.load('evo_tron1/assets/', 'neuropol x rg.ttf', 10);
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

  void destroy() {
    for (var texture in texts) {
      texture.destroy();
    }
    ttf.destroy();
  }
}
