import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:sdl2/sdl2.dart';

import '../../gui/window.dart';

// Text is rendered to a Surface and then copied into a texture for rendering.
class TTFont {
  Pointer<TtfFont> font = nullptr;
  late Rectangle<double> posTextRect;
  late Rectangle<double> squareRect;
  late Pointer<SdlSurface> textSurface;
  late Pointer<SdlTexture> textTexture;
  int screenWidth = 0;
  int screenHeight = 0;

  void initialize(int screenWidth, int screenHeight) {
    this.screenWidth = screenWidth;
    this.screenHeight = screenHeight;
    ttfInit();
  }

  int load(String relativePath, String fontFile, int pointSize) {
    var filePath = p.join(io.Directory.current.path, relativePath, fontFile);

    var ioFile = io.File(filePath);

    if (ioFile.existsSync()) {
      font = TtfFontEx.open(filePath, pointSize);
    } else {
      print('Unable to load font: \'$filePath\'!\n'
          'SDL2_ttf Error: ${ttfGetError()}\n');
      return -1;
    }

    return 0;
  }

  int setText(String text, Pointer<SdlRenderer> renderer) {
    // Find draw text onto a surface.
    textSurface = font.renderUtf8Shaded(
        text,
        SdlColorEx.rgbaToU32(0, 0, 0, SDL_ALPHA_OPAQUE),
        SdlColorEx.rgbaToU32(255, 255, 255, SDL_ALPHA_OPAQUE));
    close();

    if (textSurface == nullptr) {
      print('Unable to render text surface!\n'
          'SDL2_ttf Error: ${ttfGetError()}\n');
      return -2;
    }

    // Create texture from surface pixels which also yields a width and height.
    textTexture = renderer.createTextureFromSurface(textSurface);
    if (textTexture == nullptr) {
      print('Unable to create texture from rendered text!\n'
          'SDL2 Error: ${sdlGetError()}\n');
      return -3;
    }

    // Now that the surface has been transferred to a texture we can dispose
    // of the surface.
    textSurface.free();

    return 0;
  }

  void setPosition(double left, double top) {
    // Screen area restriction
    squareRect = Rectangle<double>(
        screenWidth / 2 - screenHeight / 2 / 2,
        screenHeight / 2 - screenHeight / 2 / 2,
        screenHeight / 2,
        screenHeight / 2);

    // (screenWidth - textSurface.ref.w) / 2, //   X
    // squareRect.top - textSurface.ref.h - 10, // Y

    // Create a rectangle to position and size the text.
    posTextRect = Rectangle<double>(
        left,
        top,
        textSurface.ref.w.toDouble(), //            Area X
        textSurface.ref.h.toDouble()); //           Area Y
  }

  void draw(Pointer<SdlRenderer> renderer, int r, int g, int b,
      {int a = SDL_ALPHA_OPAQUE}) {
    renderer.setDrawColor(r, g, b, a);
    renderer.copy(textTexture, dstrect: posTextRect);
  }

  void draw2(Window window, int r, int g, int b, {int a = SDL_ALPHA_OPAQUE}) {
    window.update(textTexture);
  }

  void close() {
    font.close();
  }
}
