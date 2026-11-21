import 'package:equatable/equatable.dart';

/// The offer pop-up the manager shows from the dashboard (`offer` in the
/// price answers, or `GET /api/app/offer`): only a text and a 16:9 picture.
/// It never changes a price. A missing text or picture is null, and the app
/// keeps its own default for it.
class OfferPopupModel extends Equatable {
  /// The line under "you won the promotional offer", in place of the name.
  final String? text;

  /// A path on the server (put the server address in front), 16:9.
  final String? imageUrl;

  const OfferPopupModel({this.text, this.imageUrl});

  /// Null when the pop-up is off: `offer` is null or `active` is false.
  static OfferPopupModel? tryParse(Object? json) {
    if (json is! Map || json['active'] == false) return null;
    String? clean(Object? v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    return OfferPopupModel(
      text: clean(json['text']),
      imageUrl: clean(json['image_url']),
    );
  }

  @override
  List<Object?> get props => [text, imageUrl];
}
