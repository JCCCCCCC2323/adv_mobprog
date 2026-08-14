import 'package:flutter_test/flutter_test.dart';
import 'package:ocray_advmobprog/providers/theme_provider.dart';

void main() {
  test('theme provider toggles dark mode', () {
    final themeProvider = ThemeProvider();

    expect(themeProvider.isDark, isFalse);

    themeProvider.toggleTheme();

    expect(themeProvider.isDark, isTrue);
  });
}
