import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('customize dashboard screen exposes undo/redo toolbar actions', () async {
    final file = File('lib/features/dashboard/customize_dashboard_screen.dart');
    expect(file.existsSync(), isTrue);

    final content = await file.readAsString();
    expect(content.contains("tooltip: 'Undo'"), isTrue);
    expect(content.contains("tooltip: 'Redo'"), isTrue);
    expect(content.contains('Icons.undo'), isTrue);
    expect(content.contains('Icons.redo'), isTrue);
  });
}
