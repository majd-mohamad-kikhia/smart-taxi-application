import 'package:equatable/equatable.dart';

/// The stars a customer gave a driver for one trip. Given once, never
/// changed or removed.
class RideRatingModel extends Equatable {
  /// 1 to 5.
  final int value;
  final String? comment;

  /// As the server sent it; null when it didn't say.
  final String? ratedAt;

  const RideRatingModel({required this.value, this.comment, this.ratedAt});

  /// Reads a `rating` object (`{ value, comment, rated_at }`); null when the
  /// ride has none or it is not usable.
  static RideRatingModel? tryParse(Object? json) {
    if (json is! Map) return null;
    final value = json['value'];
    if (value is! num || value < 1 || value > 5) return null;
    final comment = json['comment'];
    return RideRatingModel(
      value: value.toInt(),
      comment: comment is String && comment.trim().isNotEmpty
          ? comment.trim()
          : null,
      ratedAt: json['rated_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [value, comment, ratedAt];
}
