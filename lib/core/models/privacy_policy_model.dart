import 'package:equatable/equatable.dart';

/// The privacy policy in one language — `GET /api/privacy-policy`
/// (`PrivacyPolicy` schema). One policy serves both apps. [content] is
/// Markdown and is empty until one has been published.
class PrivacyPolicyModel extends Equatable {
  final String language;
  final String content;
  final String? updatedAt;

  const PrivacyPolicyModel({
    required this.language,
    required this.content,
    this.updatedAt,
  });

  bool get isEmpty => content.trim().isEmpty;

  factory PrivacyPolicyModel.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyModel(
      language: json['language'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [language, content, updatedAt];
}
