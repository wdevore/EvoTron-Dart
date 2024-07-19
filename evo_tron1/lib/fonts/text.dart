import 'dart:ffi';
import 'dart:math';

import 'package:sdl2/sdl2.dart';

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

  void setPosition(double left, double top) {
    // posTextRect = posTextRect.setX(left).setY(top);

    posTextRect = Rectangle<double>(
        left,
        top,
        textWidth, //            Area X
        textHeight); //           Area Y
  }
}
