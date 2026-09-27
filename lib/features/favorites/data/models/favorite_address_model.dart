import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Category of a saved favorite address.
enum FavoritePlaceType { home, work, gym, family, custom }

/// Model representing a saved favorite address.
class FavoriteAddressModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? note;
  final FavoritePlaceType type;
  final bool isDefault;

  const FavoriteAddressModel({
    required this.id,
    required this.name,
    required this.address,
    this.note,
    required this.type,
    this.isDefault = false,
  });

  IconData get icon {
    return switch (type) {
      FavoritePlaceType.home => Icons.home_rounded,
      FavoritePlaceType.work => Icons.business_rounded,
      FavoritePlaceType.gym => Icons.fitness_center_rounded,
      FavoritePlaceType.family => Icons.favorite_rounded,
      FavoritePlaceType.custom => Icons.place_rounded,
    };
  }

  Color get iconColor {
    return switch (type) {
      FavoritePlaceType.home => const Color(0xFF0F4C33),
      FavoritePlaceType.work => const Color(0xFF1E40AF),
      FavoritePlaceType.gym => const Color(0xFFFF6535),
      FavoritePlaceType.family => const Color(0xFFE11D48),
      FavoritePlaceType.custom => const Color(0xFF6B7280),
    };
  }

  Color get iconBackground {
    return switch (type) {
      FavoritePlaceType.home => const Color(0xFFE8F5EE),
      FavoritePlaceType.work => const Color(0xFFEFF6FF),
      FavoritePlaceType.gym => const Color(0xFFFFF1EC),
      FavoritePlaceType.family => const Color(0xFFFFF1F2),
      FavoritePlaceType.custom => const Color(0xFFF1F3F2),
    };
  }

  FavoriteAddressModel copyWith({
    String? id,
    String? name,
    String? address,
    String? note,
    FavoritePlaceType? type,
    bool? isDefault,
  }) {
    return FavoriteAddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      note: note ?? this.note,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [id, name, address, note, type, isDefault];
}
