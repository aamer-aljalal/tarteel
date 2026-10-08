import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return;

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.contains('main.dart'));

  int updatedCount = 0;

  for (var file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Remove const keyword from common UI elements to prevent const errors with screenutil
    final constRegex = RegExp(r'const\s+(SizedBox|Padding|EdgeInsets|TextStyle|Icon|Text|Container|Row|Column|BorderRadius|Radius|BoxDecoration|BoxConstraints|RoundedRectangleBorder|AnimatedContainer|FlexibleSpaceBar)\b');
    content = content.replaceAllMapped(constRegex, (m) => m[1] ?? '');
    
    // Also remove const from lists
    content = content.replaceAll(RegExp(r'const\s+\['), '[');

    // Replace dimensions
    content = content.replaceAllMapped(RegExp(r'\b(width|horizontal):\s*([0-9]+(\.[0-9]+)?)(?![\.a-zA-Z_])'), (m) => '${m[1]}: ${m[2]}.w');
    content = content.replaceAllMapped(RegExp(r'\b(height|vertical|toolbarHeight|expandedHeight):\s*([0-9]+(\.[0-9]+)?)(?![\.a-zA-Z_])'), (m) => '${m[1]}: ${m[2]}.h');
    content = content.replaceAllMapped(RegExp(r'\b(fontSize|size):\s*([0-9]+(\.[0-9]+)?)(?![\.a-zA-Z_])'), (m) => '${m[1]}: ${m[2]}.sp');
    content = content.replaceAllMapped(RegExp(r'Radius\.circular\(\s*([0-9]+(\.[0-9]+)?)\s*\)'), (m) => 'Radius.circular(${m[1]}.r)');
    content = content.replaceAllMapped(RegExp(r'BorderRadius\.circular\(\s*([0-9]+(\.[0-9]+)?)\s*\)'), (m) => 'BorderRadius.circular(${m[1]}.r)');
    content = content.replaceAllMapped(RegExp(r'EdgeInsets\.all\(\s*([0-9]+(\.[0-9]+)?)\s*\)'), (m) => 'EdgeInsets.all(${m[1]}.w)');

    if (content != original) {
       if (!content.contains('package:flutter_screenutil/flutter_screenutil.dart')) {
          content = "import 'package:flutter_screenutil/flutter_screenutil.dart';\n$content";
       }
       file.writeAsStringSync(content);
       print('Updated ${file.path}');
       updatedCount++;
    }
  }
  print('Total updated files: $updatedCount');
}
