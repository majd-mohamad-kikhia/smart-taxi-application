/// Closing lines of every WhatsApp message the app sends to a customer:
/// an invitation to get the app, with its download page.
const String whatsAppGetAppFooter =
    'حمل التطبيق الان\nhttps://smart-taxi.co/get-app';

/// [message] with [whatsAppGetAppFooter] on its own lines at the end.
String withGetAppFooter(String message) => '$message\n\n$whatsAppGetAppFooter';

/// Country code added to a local number ("0991234567") for WhatsApp, which
/// only knows international numbers.
const String whatsAppDefaultCountryCode = '963';

/// [phone] as WhatsApp wants it: international digits only, no "+" or "00"
/// ("0991 234 567" → "963991234567"). Null when it has too few digits to be
/// a phone number.
String? whatsAppNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0')) {
    digits = '$whatsAppDefaultCountryCode${digits.substring(1)}';
  } else if (digits.length == 9) {
    digits = '$whatsAppDefaultCountryCode$digits';
  }
  return digits.length < 10 ? null : digits;
}
