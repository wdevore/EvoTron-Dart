import 'dart:ffi';
import 'dart:io';
import 'package:basic_shell/gui/raster_buffer.dart';
import 'package:basic_shell/gui/window.dart';
import 'package:ffi/ffi.dart';
import 'package:sdl3/sdl3.dart';
// import 'package:sdl3/sdl3/ex/dart/native_type.dart';
// import 'package:sdl3/sdl3/generated/const_sdl.dart';
// import 'package:sdl3/sdl3/generated/lib_sdl_error.dart';
// import 'package:sdl3/sdl3/generated/lib_sdl_events.dart';
// import 'package:sdl3/sdl3/generated/lib_sdl_init.dart';
// import 'package:sdl3/sdl3/generated/lib_sdl_render.dart';
// import 'package:sdl3/sdl3/generated/lib_sdl_timer.dart';
// import 'package:sdl3/sdl3/generated/struct_sdl.dart';

import '../fonts/raster/ttf_font.dart';

// The gui shows two types of information:
// 1) Spike propagation via images,
// 2) Network topology
//
// It does this via a Scenegraph.
// SDL2 is used for rendering.
StringBuffer keyBuffer = StringBuffer();
bool keyBuffReady = false;
String keyCode = '';

// This filter is needed because calling sdlDelay locks the thread
// while delaying which prevents any input polling. This causes
// keypress events to be lost making it diffult to exit the app.
int myEventFilter(Pointer<Uint8> running, Pointer<SdlEvent> event) {
  switch (event.type) {
    case SDL_QUIT:
      running.value = 0;
      break;
    case SDL_KEYDOWN:
      var pKey = event.key; //.cast<SdlKeyboardEvent>();
      int scanCode = 0; //pKey.scancode;
      int sym = 0; //pKey.sym;
      print(scanCode);
      // print(event.key.keysym[0].mod);
      // var keys = sdlGetKeyboardState(nullptr);

      // aka backtick '`' key
      if (scanCode == SDL_SCANCODE_GRAVE) {
        running.value = 0;
        break;
      }

      if (scanCode == SDL_SCANCODE_RETURN) {
        stdout.write('\r');
        keyBuffReady = true;
        break;
      }

      if (scanCode >= SDL_SCANCODE_A && scanCode <= SDL_SCANCODE_0) {
        keyCode = String.fromCharCode(sym);
        keyBuffer.write(keyCode);
        stdout.write(keyCode);

        break;
      }

    // if (keys[SDL_SCANCODE_GRAVE] != 0) {
    //   running.value = 0;

    default:
      break;
  }
  return 1;
}

class Gui {
  static const dimensionScale = 5;
  static const winWidth = 200 * dimensionScale;
  static const winHeight = 100 * dimensionScale;
  static const scale = 1;
  static const fPS = 60;
  static const frameTargetTime = 1000 ~/ fPS;

  late Window _window;
  late RasterBuffer _rb;

  late Pointer<Uint8> _running;
  late Pointer<SdlEvent> _event;

  int _previousFrameTime = 0;

  // Used to control constant animation rates regardless of
  // FPS or frame render time. For example:
  // camera.moveUp(3.0, deltaTime);
  double _deltaTime = 0;

  late TTFont ttf;

  /// Make sure to call shutdown(...) if status < 0
  int initialize() {
    _window = Window(winWidth, winHeight, scale);

    int status = _window.init();
    if (status == -1) {
      return status;
    }

    status = _window.create('Software renderer');

    _rb = RasterBuffer();

    status = _rb.create(_window.renderer!, winWidth, winHeight);
    if (status == -1) {
      print('Unable to create texture: ${sdlGetError()}');
      return -4;
    }

    ttf = TTFont();
    ttf.initialize(winWidth, winHeight);

    int fontStatus = ttf.load('evo_tron1/assets/', 'neuropol x rg.ttf', 40);
    if (fontStatus < 0) {
      return fontStatus;
    }

    int ttfStatus = ttf.setText("Hello World", _window.renderer!);
    if (ttfStatus < 0) {
      return ttfStatus;
    }

    _running = calloc<Uint8>();
    _running.value = 1;
    sdlSetEventFilter(
        Pointer.fromFunction<Int32 Function(Pointer<Uint8>, Pointer<SdlEvent>)>(
                myEventFilter, 0)
            .cast(),
        _running);

    _event = calloc<SdlEvent>();

    return 0;
  }

  Window get window => _window;

  bool get running => _running.value == 1;

  void pre() {
    // Get a delta time factor converted to seconds to be used to update our
    // game objects. Or, how many units to change per second.
    _deltaTime = (sdlGetTicks() - _previousFrameTime) / 1000.0;

    _previousFrameTime = adjustFPS(_previousFrameTime, _event);

    // -------------------------------
    // Process input
    // -------------------------------
    // We must poll so that the filter works correctly
    sdlPollEvent(_event);

    // -------------------------------
    // Update: Draw to custom texture buffer
    // -------------------------------
    // _rb.begin();

    // _rb.clear(_window.renderer!);
  }

  void preRender() {}

  void postRender() {
    ttf.draw2(_window, 255, 255, 255);
    // ttf.setPosition(100, 100);
    // ttf.draw(_window.renderer!, 255, 255, 255);
    // _window.update(ttf.textTexture);
  }

  void post() {
    // _rb.end();

    // -------------------------------
    // Render: Display buffer
    // -------------------------------
    _window.present(); // _rb.texture
  }

  // Using this method REQUIRES the usage of a event filter.
  int adjustFPS(int previousFrameTime, Pointer<SdlEvent> event) {
    // Wait some time until we reach the target frame time in milliseconds
    int timeToWait = frameTargetTime - (sdlGetTicks() - previousFrameTime);

    // Only delay execution if we are running too fast
    if (timeToWait > 0 && timeToWait <= frameTargetTime) {
      sdlDelay(timeToWait);
      // Polling immediately after delay improves detecting events.
      sdlPollEvent(event);
    }

    return sdlGetTicks();
  }

  void shutdown() {
    _running.callocFree();
    _event.callocFree();

    _rb.destroy();

    _window.destroy();

    sdlQuit();
  }

  void abort(int status) {
    switch (status) {
      case -2:
        sdlQuit();
        break;
      case -3:
      case -4:
        _window.destroy();
        sdlQuit();
        break;
    }
  }

  void drawLine(double x1, double y1, double x2, double y2) {
    sdlSetRenderDrawColor(_window.renderer!, 255, 128, 0, 255);
    sdlRenderLine(_window.renderer, x1, y1, x2, y2);
  }
}
