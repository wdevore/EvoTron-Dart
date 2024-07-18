import 'dart:isolate';

bool isRunning = false;
bool isExit = false;

simIsolate(SendPort sendPort) async {
  print('Simulation isolate has started');

  // Bind ports
  ReceivePort port = ReceivePort();

  sendPort.send(port.sendPort);

  monitorPort(port, sendPort);

  // Begin loop - sleep for N(ms) per loop
  for (; !isExit;) {
    if (isRunning) {
      // print('Emulation is running...');
      sendPort.send(['Msg', 'Sim is running...']);
    }
    // else {
    //   print('Emulation is stopped...');
    // }

    await Future.delayed(Duration(milliseconds: 1000));
  }

  sendPort.send(['Exited', 'Bye from Sim Isolate']);
}

void monitorPort(ReceivePort port, SendPort sendPort) {
  port.listen((msg) {
    String data = msg;
    // print('Sim Isolate: $data, $isExit');
    switch (data) {
      case 'Stop':
        sendPort.send(['Stopping', 'Simulation stopping']);
        // print('Sim Isolate: request stop.');
        isRunning = false;
        break;
      case 'Run':
        sendPort.send(['Running', 'Simulation running']);
        isRunning = true;
        break;
      case 'Info':
        // print('Sim Isolate: sending info.');
        sendPort.send(['Info', 'running=$isRunning']);
        break;
      case 'Exit':
        sendPort.send(['Exit', 'running=$isRunning']);
        // print('Sim Isolate: request exit.');
        isExit = true;
        break;
    }
  });
}
