import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('.withOpacity(')) {
      content = content.replaceAllMapped(
        RegExp(r'\.withOpacity\(([^)]+)\)'), 
        (m) => '.withValues(alpha: ${m.group(1)})'
      );
      file.writeAsStringSync(content);
    }
  }
  print('Done fixing withOpacity');
}
