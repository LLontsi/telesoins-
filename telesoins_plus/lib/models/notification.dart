import 'package:flutter/foundation.dart';

enum NotificationType {
  appointment,
  message,
  prescription,
  urgent,
  system
}

class UserNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final String? targetType;
  final String? targetId;

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.targetType,
    this.targetId,
  });

  // Méthode pour copier une notification avec des changements
  UserNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    NotificationType? type,
    String? targetType,
    String? targetId,
  }) {
    return UserNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
    );
  }

  // Depuis JSON
  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      type: _parseNotificationType(json['type']),
      targetType: json['target_type'],
      targetId: json['target_id'],
    );
  }

  // Vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'type': describeEnum(type),
      'target_type': targetType,
      'target_id': targetId,
    };
  }

  // Helper pour convertir le type depuis la chaîne JSON
  static NotificationType _parseNotificationType(String typeStr) {
    switch (typeStr) {
      case 'appointment':
        return NotificationType.appointment;
      case 'message':
        return NotificationType.message;
      case 'prescription':
        return NotificationType.prescription;
      case 'urgent':
        return NotificationType.urgent;
      default:
        return NotificationType.system;
    }
  }
}