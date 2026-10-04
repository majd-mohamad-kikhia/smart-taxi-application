/// How the ride was ordered (`order_source`): from the customer app, or by
/// the office for a WhatsApp / phone caller.
enum RideOrderSource {
  app,
  whatsapp,
  call;

  /// Unknown or missing values count as an app order.
  static RideOrderSource fromWire(Object? value) => switch (value) {
    'whatsapp' => whatsapp,
    'call' => call,
    _ => app,
  };

  /// Written by the office — the customer often has no app, so the bill is
  /// sent to them on WhatsApp.
  bool get isOffice => this != app;
}
