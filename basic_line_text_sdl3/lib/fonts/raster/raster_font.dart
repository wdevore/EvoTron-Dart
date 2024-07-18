import 'dart:io' as io;

import 'package:path/path.dart' as p;

// Render each char to an texture atlas
// Each char is 8x8 pixels
// All chars are in ascii order

class RasterFont {
  int loadFont(String relativePath, String fontFile) {
    var filePath = p.join(io.Directory.current.path, relativePath, fontFile);

    var ioFile = io.File(filePath);
    List<String> lines;

    if (ioFile.existsSync()) {
      lines = ioFile.readAsLinesSync();
    } else {
      return -1;
    }

    // Triple quotes are needed because of certain special chars
    String expr =
        r"""([!"#$%&'\(\)*+,-./:;<=>?@\[\]^_`{|}~0-9\w]{1,1}) ([0-9xA-F ]+)""";

    final RegExp regExp = RegExp(expr);

    for (var line in lines) {
      RegExpMatch? match = regExp.firstMatch(line);

      if (match != null) {
        // Build a 8x8 pixel map to be render to an Atlas.
        // Each byte is a raster line of the char which means there
        // is 8 lines each with 8 pixels.
        // Padding is added to each pixmap yielding a 10x10 pixmap.
        String char = match[1]!;
        List<String> hexCodes = match[2]!.split(' ');
        print(char);
      }
    }

    return 0;
  }
}
