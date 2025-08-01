import 'dart:io';
//import 'package:flutter/material.dart';

class Message {
  final String id;
  final String consultationId;
  final String senderId;
  final String senderName;
  final String content;
  final String? attachmentUrl;
  final DateTime timestamp;
  final bool isRead;
  final File? localAttachment; // Pour les pièces jointes non encore téléchargées

  Message({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.attachmentUrl,
    required this.timestamp,
    required this.isRead,
    this.localAttachment,
  });

  // Création à partir de JSON (réponse API)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      consultationId: json['consultation'],
      senderId: json['sender']['id'],
      senderName: json['sender']['full_name'] ?? 'Utilisateur',
      content: json['content'],
      attachmentUrl: json['attachment'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'],
    );
  }

  // Conversion en JSON pour envoi API
  Map<String, dynamic> toJson() {
    return {
      'consultation': consultationId,
      'content': content,
      // L'API gère automatiquement le sender avec l'authentification
    };
  }

  // Créer une copie du message avec des champs modifiés
  Message copyWith({
    String? id,
    String? consultationId,
    String? senderId,
    String? senderName,
    String? content,
    String? attachmentUrl,
    DateTime? timestamp,
    bool? isRead,
    File? localAttachment,
  }) {
    return Message(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      localAttachment: localAttachment ?? this.localAttachment,
    );
  }

  // Vérifier si le message a une pièce jointe
  bool get hasAttachment => attachmentUrl != null || localAttachment != null;
}
