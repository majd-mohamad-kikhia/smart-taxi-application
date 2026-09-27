import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Category of a notification, driving its icon and color.
enum NotificationType { tripUpdate, promo, payment, system }

/// Model representing a single notification entry.
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime dateTime;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.dateTime,
  });

  IconData get icon {
    return switch (type) {
      NotificationType.tripUpdate => Icons.directions_car_rounded,
      NotificationType.promo => Icons.local_offer_rounded,
      NotificationType.payment => Icons.account_balance_wallet_rounded,
      NotificationType.system => Icons.info_rounded,
    };
  }

  Color get iconColor {
    return switch (type) {
      NotificationType.tripUpdate => const Color(0xFF0F4C33),
      NotificationType.promo => const Color(0xFFFF6535),
      NotificationType.payment => const Color(0xFF1E40AF),
      NotificationType.system => const Color(0xFF6B7280),
    };
  }

  Color get iconBackground {
    return switch (type) {
      NotificationType.tripUpdate => const Color(0xFFE8F5EE),
      NotificationType.promo => const Color(0xFFFFF1EC),
      NotificationType.payment => const Color(0xFFEFF6FF),
      NotificationType.system => const Color(0xFFF1F3F2),
    };
  }

  @override
  List<Object?> get props => [id, title, message, type, dateTime];
}
