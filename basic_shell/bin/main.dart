// The main isolate that binds SDL2 and Console and Sim-isolate

import 'package:basic_shell/gui/gui.dart';

int main(List<String> arguments) {
  Gui gui = Gui();

  int startStatus = gui.initialize();
  if (startStatus < 0) {
    gui.abort(startStatus);
    return startStatus;
  }

  while (gui.running) {
    gui.pre();

    gui.render();

    gui.post();
  }

  gui.shutdown();

  return 0;
}
