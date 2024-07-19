import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:sdl2/sdl2.dart';

// Text is rendered to a Surface and then copied into a texture for rendering.
class TTFont {
  Pointer<TtfFont> font = nullptr;
  late Rectangle<double> posTextRect;

  late Pointer<SdlSurface> textSurface;
  double textWidth = 0;
  double textHeight = 0;

  late Pointer<SdlTexture> textTexture;

  final Pointer<SdlRenderer> renderer;

  TTFont(this.renderer);

  void initialize() {
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

  Pointer<SdlTexture>? generateText(
      String text, List<int> fgColor, List<int> bgColor) {
    // Draw text onto a surface.
    Pointer<SdlSurface> textSurface = font.renderUtf8Shaded(
        text,
        SdlColorEx.rgbaToU32(
          fgColor[0],
          fgColor[1],
          fgColor[2],
          fgColor[3],
        ),
        SdlColorEx.rgbaToU32(
          bgColor[0],
          bgColor[1],
          bgColor[2],
          bgColor[3],
        ));
    // SdlColorEx.rgbaToU32(255, 255, 255, SDL_ALPHA_OPAQUE));

    if (textSurface == nullptr) {
      print('Unable to render text surface!\n'
          'SDL2_ttf Error: ${ttfGetError()}\n');
      return null;
    }

    // Create texture from surface pixels which also yields a width and height.
    Pointer<SdlTexture> textTexture =
        renderer.createTextureFromSurface(textSurface);
    if (textTexture == nullptr) {
      print('Unable to create texture from rendered text!\n'
          'SDL2 Error: ${sdlGetError()}\n');
      return null;
    }

    textWidth = textSurface.ref.w.toDouble();
    textHeight = textSurface.ref.h.toDouble();

    // Now that the surface has been transferred to a texture AND we have
    // captured any relative information, we can dispose of the surface.
    textSurface.free();

    return textTexture;
  }

  Rectangle<double> createPosRectangle(double left, double top) {
    return Rectangle<double>(
        left,
        top,
        textWidth, //            Area X
        textHeight); //           Area Y
  }

  void destroy() {
    font.close();
  }
}
