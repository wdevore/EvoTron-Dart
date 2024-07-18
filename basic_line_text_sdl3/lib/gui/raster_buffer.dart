// RasterBuffer provides a memory mapped RGBA and Z buffer
// This buffer must be blitted to another buffer, for example,
// PNG or display buffer (like SDL).
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:sdl3/sdl3/ex/sdl/sdl_renderer.dart';
import 'package:sdl3/sdl3/ex/sdl/sdl_texture.dart';
import 'package:sdl3/sdl3/generated/const_sdl.dart';
import 'package:sdl3/sdl3/generated/struct_sdl.dart';
import 'package:sdl3/sdl3/lib_sdl_ex.dart';

import 'colors.dart' as palette;

class RasterBuffer {
  int width = 0;
  int height = 0;
  bool alphaBlending = false;
  int size = 0;

  // Pen colors
  int pixelColor = palette.Colors().black;
  int clearColor = palette.Colors().black;

  late Pointer<SdlTexture> texture;
  Pointer<Pointer<Uint32>> texturePixels = calloc<Pointer<Uint32>>();
  Pointer<Int32> texturePitch = calloc<Int32>();
  Pointer<Uint32>? bufferAddr;
  Pointer<Uint32>? posOffset;

  late Uint32List textureAsList;

  int pointSize = 2;

  int create(Pointer<SdlRenderer> renderer, int width, int height) {
    this.width = width;
    this.height = height;

    // create texture
    texture = renderer.createTexture(
        SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STREAMING, width, height);

    if (texture == nullptr) {
      return -1;
    }

    size = width * height;

    return 0;
  }

  void destroy() {
    texture.destroy();
  }

  void begin() {
    texture.lock(nullptr, texturePixels, texturePitch);
    bufferAddr = texturePixels.value;
    textureAsList = bufferAddr!.asTypedList(size);
  }

  void end() => texture.unlock();

  void clear(Pointer<SdlRenderer> renderer) {
    textureAsList.fillRange(0, size - 1, clearColor);
  }

  void setPixelXY(int color, int x, int y) {
    if (x < 0 || x > width || y < 0 || y > height) {
      return;
    }
    pixelColor = color;
    int offset = x + (y * width);
    posOffset = bufferAddr! + offset;
    posOffset?.value = pixelColor;
  }

  void setPixel(int x, int y) {
    if (x < 0 || x > width || y < 0 || y > height) {
      return;
    }
    int offset = x + (y * width);
    posOffset = bufferAddr! + offset;
    posOffset?.value = pixelColor;
  }

  // DEPRECATED: (1-t)*a + t*b
  double lerp(double t, double a, double b) {
    return (1 - t) * a + t * b;
  }

  void setPixelByOffset(int color, int offset) {
    pixelColor = color;
    posOffset = bufferAddr! + offset;
    posOffset?.value = pixelColor;
  }

  int pixelAt(int x, int y) {
    if (x < 0 || x > width || y < 0 || y > height) {
      return -1;
    }
    int offset = x + (y * width);
    posOffset = bufferAddr! + offset;
    return posOffset?.value ?? -2;
  }

  void drawGrid() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (x % 10 == 0 || y % 10 == 0) {
          setPixel(x, y);
        }
      }
    }
  }

  void drawGridDots() {
    for (var y = 0; y < height; y += 10) {
      for (var x = 0; x < width; x += 10) {
        setPixel(x, y);
      }
    }
  }

  void drawRectangle(int x, int y, int width, int height) {
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        setPixel(x + i, y + j);
      }
    }
  }

  void drawRectangleWithColor(int x, int y, int width, int height, int color) {
    pixelColor = color;
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        setPixel(x + i, y + j);
      }
    }
  }

  void drawDDALine(int x0, int y0, int x1, int y1) {
    int deltaX = (x1 - x0);
    int deltaY = (y1 - y0);

    int longestSideLength =
        (deltaX.abs() >= deltaY.abs()) ? deltaX.abs() : deltaY.abs();

    double xInc = deltaX / longestSideLength.toDouble();
    double yInc = deltaY / longestSideLength.toDouble();

    double currentX = x0.toDouble();
    double currentY = y0.toDouble();

    for (int i = 0; i <= longestSideLength; i++) {
      setPixel(currentX.round(), currentY.round());
      currentX += xInc;
      currentY += yInc;
    }
  }
}
