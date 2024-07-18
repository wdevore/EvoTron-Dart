// The main isolate that binds SDL2 and Console and Sim-isolate

import 'dart:io' as io;
import 'dart:isolate';

import 'package:evo_tron1/gui/gui.dart';
import 'package:evo_tron1/simulator/sim_isolate.dart';

void main(List<String> arguments) async {
  print('Starting Evo Tron 1 simulation application.');

  // ----------- Load font -----------
  // RasterFont rf = RasterFont()
  //   ..loadFont('evo_tron1/assets', 'raster_font.data');

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

  io.stdout.write('>');
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
          io.stdout.write('>');
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
  io.exit(0);
}

void monitorPort(Stream<dynamic> stream) {
  stream.listen(
    (message) {
      // List data = message as List;
      // print(data);
      io.stdout.write('\r\n');
      switch (message[0]) {
        case 'Info':
          print('### ${message[0]}');
          print('### ${message[1]}');
          io.stdout.write('>');
          break;
        case 'Exited':
          print('${message[1]}');
          print('Enter "`" to exit app.');
          break;
        case 'Msg':
          io.stdout.write('${message[1]}');
          break;
        case 'Stopping':
        case 'Running':
          print('${message[1]}');
          break;
        case 'Exit':
          break;
        default:
          io.stdout.write('>');
          break;
      }
    },
  );
}
