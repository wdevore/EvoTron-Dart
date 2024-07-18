A sample command-line application with an entrypoint in `bin/`, library code in `lib/`, and example unit test in `test/`.

# Launch setup
Add entry to *launch.json* as:
```json
        {
            "name": "EvoTron",
            "cwd": "/media/iposthuman/Extreme SSD/Development/Dart/EvoTron-Dart/",
            "program": "basic_shell/bin/main.dart",
            "request": "launch",
            "type": "dart",
            "args": ["standard.json"]
        },
```

# Tasks
- Add configuration cmd line parm to select different configurations.
- Add check for RAM disk mount (current set at 4Gig)

# Sim Isolate send to main
The simulation isolate writes data to an image. This images can be *sent* to the main isolate. However, it is better that main reads a file instead.
The images are stored in RAM disc as compressed PNGs. These can be moved to disc if needed.

- Option #1: The simulation isolate could send the file name back and let the main isolate access and show image.
- Option #2: The sim isolate sends a byte buffer of Uint8List. (DOES NOT WORK)
- Option #3: FFI binding to a simply C program that exposes two buffers.
- Option #4: Use TransferableTypedData class https://api.flutter.dev/flutter/dart-isolate/TransferableTypedData-class.html and an example: https://gist.github.com/guid-empty/b5d36cd4c89727135ee4fceec440370b


```
https://github.com/dart-lang/language/issues/124:

You can use dart:ffi to allocate memory on the C heap. The resulting buffer (of type Pointer<Uint8>) can be viewed as a typed list (via Pointer<Uint8>.asTypedList(<length>) - see api docs). You can send the address of that pointer to another isolate and use asTypedList(), then you'll have access to the same bytes from multiple isolates. Though you won't have strong memory ordering garantees if you have read-write or write-write conflicts. You'll also need to free the memory manually (ensuring that there's no more references to it.
```