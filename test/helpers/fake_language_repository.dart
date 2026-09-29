import 'package:mshoar/core/enums/user_role.dart';
import 'package:mshoar/core/localization/language_repository.dart';

/// In-memory [LanguageRepository]: records what was sent to the "server"
/// and fails on demand.
class FakeLanguageRepository implements LanguageRepository {
  final List<(UserRole, String)> saved = [];
  LanguageException? failure;

  @override
  Future<void> saveLanguage(UserRole role, String languageCode) async {
    final error = failure;
    if (error != null) throw error;
    saved.add((role, languageCode));
  }
}
