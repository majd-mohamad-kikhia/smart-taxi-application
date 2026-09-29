import 'package:equatable/equatable.dart';

/// The terms and conditions text for one app (rider / driver) in one
/// language — `GET /api/terms/{audience}` (`Terms` schema). [content] is
/// exactly what the manager wrote (line breaks kept) and is empty until
/// one has been published.
class TermsModel extends Equatable {
  final String language;
  final String content;
  final String? updatedAt;

  const TermsModel({
    required this.language,
    required this.content,
    this.updatedAt,
  });

  bool get isEmpty => content.trim().isEmpty;

  factory TermsModel.fromJson(Map<String, dynamic> json) {
    return TermsModel(
      language: json['language'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [language, content, updatedAt];
}
