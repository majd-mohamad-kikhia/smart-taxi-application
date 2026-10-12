import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/utils/format_price.dart';
import 'new_order_alert.dart';

/// Whether the app is on screen. Before the first frame the state is unknown;
/// that counts as on screen.
bool appIsInForeground() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null || state == AppLifecycleState.resumed;
}

/// A new order while the app is in the background or the screen is off: shown
/// like an incoming call outside the app (a full-screen notification that
/// rings and opens the app on the order). Does nothing while the app is on
/// screen, where the in-app sound and the order card do the job.
///
/// Only one order rings at a time: a newer one replaces it, and it goes away
/// when the order is taken, withdrawn or the driver goes offline.
class IncomingOrderCallAlert implements NewOrderAlert {
  static const _notificationId = 7001;
  static const _askedKey = 'incoming_order_full_screen_asked';

  final LocalNotificationService _notifications;
  final bool Function() _isForeground;
  bool _showing = false;

  IncomingOrderCallAlert(
    this._notifications, {
    bool Function()? isForeground,
  }) : _isForeground = isForeground ?? appIsInForeground;

  @override
  Future<void> start({OrderOfferModel? order}) async {
    if (_isForeground()) return;
    try {
      _showing = true;
      final l10n = AppStrings.current;
      await _notifications.showIncomingOrderCall(
        id: _notificationId,
        title: l10n.incomingOrderTitle,
        body: order == null
            ? l10n.incomingOrderTitle
            : l10n.incomingOrderBody(
                formatNewSyp(l10n, order.estimatedPrice),
                l10n.distanceKm(order.distanceToPickupKm.toStringAsFixed(1)),
              ),
        payload: order == null ? null : '${order.rideId}',
        timeout: AudioNewOrderAlert.duration,
      );
    } catch (e) {
      // A notification that can't be shown must never break receiving orders.
      _showing = false;
      debugPrint('IncomingOrderCallAlert: could not show the call: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_showing) return;
    _showing = false;
    try {
      await _notifications.cancel(_notificationId);
    } catch (e) {
      debugPrint('IncomingOrderCallAlert: could not clear the call: $e');
    }
  }

  /// Once, the first time the driver is online: on Android 14+ asks for the
  /// right to take over the screen (opens the system's setting). Never again,
  /// so the driver is not nagged.
  Future<void> askForScreenTakeoverOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_askedKey) ?? false) return;
      await prefs.setBool(_askedKey, true);
      await _notifications.requestFullScreenIntentPermission();
    } catch (e) {
      debugPrint('IncomingOrderCallAlert: could not ask for permission: $e');
    }
  }
}

/// Fans one alert out to several (the in-app sound and the call outside the
/// app): a failing one never stops the others.
class CompositeNewOrderAlert implements NewOrderAlert {
  final List<NewOrderAlert> alerts;

  const CompositeNewOrderAlert(this.alerts);

  @override
  Future<void> start({OrderOfferModel? order}) => _all((a) => a.start(order: order));

  @override
  Future<void> stop() => _all((a) => a.stop());

  Future<void> _all(Future<void> Function(NewOrderAlert) action) async {
    await Future.wait([
      for (final alert in alerts)
        action(alert).catchError((Object e) => debugPrint('NewOrderAlert: $e')),
    ]);
  }
}
