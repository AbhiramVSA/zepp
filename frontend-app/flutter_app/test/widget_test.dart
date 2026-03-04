import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/app_theme.dart';

void main() {
  test('AppTheme.light returns a light theme', () {
    final theme = AppTheme.light();
    expect(theme.brightness, Brightness.light);
  });

  test('AppTheme.dark returns a dark theme', () {
    final theme = AppTheme.dark();
    expect(theme.brightness, Brightness.dark);
  });
}
