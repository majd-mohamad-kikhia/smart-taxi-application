import '../localization/app_strings.dart';

/// Centralized form-field validators shared by every auth screen
/// (customer and driver) — kept in sync with the rules documented in
/// `lib/features/auth/data/swagger.json`.
///
/// Messages are resolved through [AppStrings] at validation time, so they
/// come out in whichever language is active.
class AuthValidators {
  AuthValidators._();

  static final RegExp _phoneRegExp = RegExp(r'^\+?\d{8,15}$');
  static final RegExp _nameRegExp =
      RegExp(r"^[\p{L} '\-]{2,100}$", unicode: true);

  static String? phone(String? value) {
    if (!_phoneRegExp.hasMatch(value?.trim() ?? '')) {
      return AppStrings.current.valPhone;
    }
    return null;
  }

  /// Login only checks presence — the API doesn't re-check strength on
  /// login, so existing accounts are never locked out.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.current.valPasswordRequired;
    }
    return null;
  }

  static String? signupPassword(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        password.length > 64 ||
        password.contains(' ')) {
      return AppStrings.current.valPasswordRule;
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) {
      return AppStrings.current.valPasswordMismatch;
    }
    return null;
  }

  static String? name(String? value) {
    if (!_nameRegExp.hasMatch(value?.trim() ?? '')) {
      return AppStrings.current.valNameLetters;
    }
    return null;
  }
}
