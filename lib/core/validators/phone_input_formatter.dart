import 'package:flutter/services.dart';

/// Cleans a phone number as it is typed or pasted, so what the validator
/// checks and what is sent to the server is plain ASCII digits:
/// - Arabic-Indic (٠-٩) and Persian (۰-۹) digits become 0-9;
/// - spaces, dashes, dots, parentheses and invisible direction marks are
///   dropped ("0599 123-456" and a number pasted from a chat both work).
/// A leading "+" is kept.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  static const int _arabicIndicZero = 0x0660;
  static const int _persianZero = 0x06F0;

  /// Space, no-break space, dash, dot, parentheses, and the invisible
  /// left-to-right / right-to-left marks and isolates a chat app may add.
  static const Set<int> _dropped = {
    0x20,
    0xA0,
    0x2D,
    0x2E,
    0x28,
    0x29,
    0x200E,
    0x200F,
    0x202A,
    0x202B,
    0x202C,
    0x2066,
    0x2067,
    0x2068,
    0x2069,
  };

  /// [value] with the same cleaning applied (for a value set from code).
  static String clean(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (_dropped.contains(rune)) continue;
      if (rune >= _arabicIndicZero && rune <= _arabicIndicZero + 9) {
        buffer.writeCharCode(0x30 + rune - _arabicIndicZero);
      } else if (rune >= _persianZero && rune <= _persianZero + 9) {
        buffer.writeCharCode(0x30 + rune - _persianZero);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = clean(newValue.text);
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
