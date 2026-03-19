import 'dart:io';

Future<void> main() async {
  final libDir = Directory('lib');
  
  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  int filesChanged = 0;
  int replacements = 0;

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  for (final file in dartFiles) {
    String content = file.readAsStringSync();
    
    if (!content.contains('AppTypography.')) continue;

    final originalContent = content;

    // Replace textTheme accesses: AppTypography.textTheme.xyz -> AppTypography.textTheme(context).xyz
    content = content.replaceAll(
      'AppTypography.textTheme.',
      'AppTypography.textTheme(context).',
    );

    // Replace handwritten/marginMeta accesses
    content = content.replaceAll(
      'AppTypography.handwritten',
      'AppTypography.handwritten(context)',
    );
    content = content.replaceAll(
      'AppTypography.marginMeta',
      'AppTypography.marginMeta(context)',
    );

    if (content != originalContent) {
      file.writeAsStringSync(content);
      filesChanged++;
      // We don't count exact replacements accurately here for simplicity, 
      // but we know we made changes
      replacements++;
    }
  }

  print('Typography Migration completed! Processed $filesChanged files.');
}
