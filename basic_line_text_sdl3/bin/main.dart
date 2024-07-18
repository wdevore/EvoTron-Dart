// The main isolate that binds SDL2 and Console and Sim-isolate

import 'dart:io';

import 'package:basic_shell/gui/gui.dart';

void main(List<String> arguments) async {
  Gui gui = Gui();

  int startStatus = gui.initialize();
  if (startStatus < 0) {
    gui.abort(startStatus);
    return;
  }

  stdout.write('>');
  while (gui.running) {
    if (keyBuffReady) {
      // print('buf: ${keyBuffer.toString()}');
      switch (keyBuffer.toString()) {
        case 'h':
        case 'help':
          print('\n--------------------------------------------');
          print('"`" tilde key terminates application');
          print('--------------------------------------------');
          stdout.write('>');
          break;
      }
      keyBuffer.clear();
      keyBuffReady = false;
    }

    gui.pre();
    gui.ttf.setPosition(100, 100);
    // gui.ttf.draw2(gui.window, 255, 255, 255);
    gui.window.copyTexture(gui.ttf.textTexture, dstrect: gui.ttf.posTextRect);
    gui.drawLine(100, 100, 200, 200);

    // // TODO implement Spikes and Topology
    // gui.preRender();

    // gui.postRender();

    gui.post();

    // We need a short delay to give the main isolate time to
    // process IO to the console. Otherwise SDL's loop dominates
    // and starves IO.
    await Future.delayed(Duration(milliseconds: 1));
  }

  gui.shutdown();

  print('\nGoodbye');
  exit(0);
}
