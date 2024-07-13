// The main isolate that binds SDL2 and Console and Sim-isolate

import 'dart:io';
import 'dart:isolate';

import 'package:basic_shell/gui/gui.dart';
import 'package:basic_shell/simulator/sim_isolate.dart';

void main(List<String> arguments) async {
  Gui gui = Gui();

  int startStatus = gui.initialize();
  if (startStatus < 0) {
    gui.abort(startStatus);
    return;
  }

  // ----------- Start emulation Isolate -----------
  // This is the receive port that the emu isolate sends data to.
  ReceivePort port = ReceivePort();

  // 'port' is a normal stream, transform it in a broadcast stream
  // so we can listen in more than one place.
  final streamOfMesssage = port.asBroadcastStream();

  await Isolate.spawn(
    simIsolate,
    port.sendPort,
    debugName: 'SimIsolate',
  );

  // Get send port of sim isolate. The first thing the sim isolate does
  // is send its "input" port (aka send port)
  SendPort simSendPort = await streamOfMesssage.first;

  monitorPort(streamOfMesssage);

  stdout.write('>');
  while (gui.running) {
    if (keyBuffReady) {
      // print('buf: ${keyBuffer.toString()}');
      switch (keyBuffer.toString()) {
        case 'r':
        case 'run':
          simSendPort.send('Run');
          break;
        case 's':
        case 'stop':
          simSendPort.send('Stop');
          break;
        case 'e':
        case 'exit':
          simSendPort.send('Stop');
          simSendPort.send('Exit');
          break;
        case 'i':
        case 'info':
          simSendPort.send('Info');
          break;
        case 'h':
        case 'help':
          print('\n--------------------------------------------');
          print('"`" tilde key terminates application');
          print('[r,run] to start or continue simulaton');
          print('[s,stop] stop or pause simulation');
          print('[e,exit] stop and exit simulation isolate');
          print('[i,info] request simulation to return information');
          print('[h,help] this help contents');
          print('--------------------------------------------');
          stdout.write('>');
          break;
      }
      keyBuffer.clear();
      keyBuffReady = false;
    }

    gui.pre();

    // TODO implement Spikes and Topology
    gui.preRender();

    gui.postRender();

    gui.post();

    // We need a short delay to give the main isolate time to
    // process IO to the console. Otherwise SDL's loop dominates
    // and starves IO.
    await Future.delayed(Duration(milliseconds: 1));
  }

  gui.shutdown();

  print('\nSimulation shutdown. Goodbye');
  exit(0);
}

void monitorPort(Stream<dynamic> stream) {
  stream.listen(
    (message) {
      // print('Main Isolate: $message');
      // List data = message as List;
      stdout.write('\r\n');
      switch (message[0]) {
        case 'Info':
          print('### ${message[0]}');
          print('### ${message[1]}');
          stdout.write('>');

          break;
        case 'Exited':
          print('${message[1]}');
          print('Enter "`" to exit app.');
          break;
        case 'Exit':
          break;
        default:
          stdout.write('>');
          break;
      }
    },
  );
}
