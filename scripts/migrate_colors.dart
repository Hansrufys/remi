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
    
    // We only want to process files that actually use AppColors (and aren't app_colors.dart itself)
    if (!content.contains('AppColors.') || file.path.contains('app_colors.dart')) {
      continue;
    }

    final originalContent = content;

    // We do a regex replacement: AppColors.COLOR_NAME -> AppColors.of(context).COLOR_NAME
    // We need to exclude 'AppColors.of' or anything that doesn't match our palette
    final colorFields = [
      'paper', 'cream', 'cardSurface', 'charcoal', 'inkLight', 'mutedText', 'borderLight',
      'bioAccent', 'bioGlow', 'bioPulse', 'bioMint', 'bioAmber',
      'tagActionable', 'tagData', 'tagInsight', 'tagProcessing',
      'glassFill', 'glassBorder', 'isDark',
    ];

    for (final color in colorFields) {
      final regex = RegExp('AppColors\\.$color\\b');
      content = content.replaceAllMapped(regex, (match) {
        if (color == 'isDark') {
           return '(Theme.of(context).brightness == Brightness.dark)';
        }
        replacements++;
        return 'AppColors.of(context).$color';
      });
    }

    // Now correctly repair the incorrect `AppColors.of(context).errorRed` replacements
    content = content.replaceAll('AppColors.of(context).errorRed', 'AppColors.errorRed');
    content = content.replaceAll('AppColors.of(context).successGreen', 'AppColors.successGreen');

    // Make sure we pass context properly to spino elements which need it explicitly now
    // Because Spinosaurus isn't a widget, we need to pass colors down or read them locally inside the widgets using it.
    
    if (content != originalContent) {
      file.writeAsStringSync(content);
      filesChanged++;
    }
  }

  print('Migration completed! Processed $filesChanged files, made $replacements replacements.');
}
