import 'dart:ffi';
import 'dart:io';
import 'package:evo_tron1/fonts/text_atlas.dart';
import 'package:evo_tron1/gui/window.dart';
import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';

import '../fonts/text.dart';

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
      int scanCode = event.key.keysym[0].scancode;
      int sym = event.key.keysym[0].sym;
      // print(scanCode);
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
  int timeToWait = 0;
  int frameTime = 0;

  late Window _window;

  late Pointer<Uint8> _running;
  late Pointer<SdlEvent> _event;

  int _previousFrameTime = 0;

  // Used to control constant animation rates regardless of
  // FPS or frame render time. For example:
  // camera.moveUp(3.0, deltaTime);
  double _deltaTime = 0;

  // late TTFont ttf;
  late TextAtlas textAtlas;

  /// Make sure to call shutdown(...) if status < 0
  int initialize() {
    _window = Window(winWidth, winHeight, scale);

    int status = _window.init();
    if (status == -1) {
      return status;
    }

    status = _window.create('Evo Tron 1');

    textAtlas = TextAtlas();
    int tatStatus = textAtlas.initialize(_window.renderer);
    if (tatStatus < 0) {
      return tatStatus;
    }
    textAtlas.addText('Hello World', 100, 100);
    textAtlas.addText('FPS:', 5, winHeight - 25);

    double xOff = 0;
    for (var i = 0; i < 10; i++) {
      textAtlas.addText(String.fromCharCode(0x30 + i), xOff, 0);
      // xOff += 20.0;
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
  }

  void preRender() {
    _window.clear();

    Text txt = textAtlas.findText('Hello World');
    if (!txt.isNil) {
      txt.draw(_window.renderer);
    }
    txt = textAtlas.findText('FPS:');
    if (!txt.isNil) {
      txt.draw(_window.renderer);
    }
    textAtlas.drawInt(frameTime, 60, winHeight - 25, 15, _window.renderer);
  }

  void postRender() {
    drawLine(100, 100, 200, 200);
  }

  void post() {
    // -------------------------------
    // Render: Display buffer
    // -------------------------------
    _window.present();
  }

  void drawLine(int x1, int y1, int x2, int y2) {
    sdlSetRenderDrawColor(_window.renderer, 255, 128, 0, 255);
    sdlRenderDrawLine(_window.renderer, x1, y1, x2, y2);
  }

  // Using this method REQUIRES the usage of a event filter.
  int adjustFPS(int previousFrameTime, Pointer<SdlEvent> event) {
    // Wait some time until we reach the target frame time in milliseconds
    timeToWait = frameTargetTime - (sdlGetTicks() - previousFrameTime);
    frameTime = timeToWait != 0 ? 1000 ~/ timeToWait : 0;

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

    textAtlas.destroy();

    _window.destroy();

    ttfQuit();
    sdlQuit();
  }

  void abort(int status) {
    switch (status) {
      case -2:
        ttfQuit();
        sdlQuit();
        break;
      case -3:
      case -4:
        _window.destroy();
        ttfQuit();
        sdlQuit();
        break;
    }
  }
}
