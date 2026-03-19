import 'dart:io';

void main() async {
  final String flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
  print('Running \$flutterCmd analyze...');
  final result = await Process.run(flutterCmd, ['analyze']);
  
  final lines = result.stdout.toString().split('\n');
  final errorRegex = RegExp(r"error.*Invalid constant value.* ([a-zA-Z0-9_\.\\\/]+):(\d+):\d+");
  final defaultRegex = RegExp(r"error.*The default value of an optional parameter must be constant.* ([a-zA-Z0-9_\.\\\/]+):(\d+):\d+");
  
  Map<String, List<int>> fileToErrorLines = {};

  for (var line in lines) {
    var match = errorRegex.firstMatch(line) ?? defaultRegex.firstMatch(line);
    if (match != null) {
      final file = match.group(1)!.trim();
      final lineNumber = int.parse(match.group(2)!);
      
      if (!fileToErrorLines.containsKey(file)) {
        fileToErrorLines[file] = [];
      }
      fileToErrorLines[file]!.add(lineNumber);
    }
  }

  print('Found errors in \${fileToErrorLines.length} files.');

  for (var file in fileToErrorLines.keys) {
    if (!File(file).existsSync()) {
      print('File not found: \$file');
      continue;
    }
    
    var contentLines = File(file).readAsLinesSync();
    var errorLines = fileToErrorLines[file]!;
    
    // Process backwards so line numbers don't shift (though we're just replacing text on the line, not adding/removing lines)
    errorLines.sort((a, b) => b.compareTo(a));

    for (var errLine in errorLines) {
      int zeroIdx = errLine - 1;
      
      // Search from the error line upwards (max 10 lines) to find 'const' and remove it 
      for (int i = zeroIdx; i >= 0 && i > zeroIdx - 15; i--) {
        if (contentLines[i].contains('const ')) {
          contentLines[i] = contentLines[i].replaceFirst('const ', '');
          break;
        }
      }
    }

    File(file).writeAsStringSync('${contentLines.join('\n')}\n');
    print('Fixed \$file');
  }
}
