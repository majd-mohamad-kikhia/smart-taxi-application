import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/order_offer_model.dart';
import '../../../../core/screen_takeover/data/screen_takeover_platform.dart';
import '../../../../core/screen_takeover/data/screen_takeover_store.dart';
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
/// With the driver's "Open the app for new orders" switch off it is a
/// ringing notification only: it neither takes over the screen nor brings
/// the app to the front.
///
/// Only one order rings at a time: a newer one replaces it, and it goes away
/// when the order is taken, withdrawn or the driver goes offline.
class IncomingOrderCallAlert implements NewOrderAlert {
  static const _notificationId = 7001;

  final LocalNotificationService _notifications;
  final ScreenTakeoverStore _takeoverStore;
  final ScreenTakeoverPlatform _takeover;
  final bool Function() _isForeground;
  bool _showing = false;

  IncomingOrderCallAlert(
    this._notifications,
    this._takeoverStore,
    this._takeover, {
    bool Function()? isForeground,
  }) : _isForeground = isForeground ?? appIsInForeground;

  @override
  Future<void> start({OrderOfferModel? order}) async {
    if (_isForeground()) return;
    try {
      _showing = true;
      final takeOver = await _takeoverStore.isEnabled();
      final l10n = AppStrings.current;
      await _notifications.showIncomingOrderCall(
        fullScreenIntent: takeOver,
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
      // The full-screen notification only takes over a locked or idle
      // screen; with another app in use the app is pulled to the front.
      if (takeOver) await _takeover.bringToFront();
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
