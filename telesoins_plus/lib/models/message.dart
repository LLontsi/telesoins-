import 'package:telesoins_plus/models/user.dart';

enum MessageType {
  text,
  image,
  document,
  audio,
  video
}

class Message {
  final int id;
  final int consultationId;
  final User sender;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;

  Message({
    required this.id,
    required this.consultationId,
    required this.sender,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      consultationId: json['consultation_id'],
      sender: User.fromJson(json['sender']),
      content: json['content'],
      type: _typeFromString(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consultation_id': consultationId,
      'sender_id': sender.id,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'attachment_url': attachmentUrl,
    };
  }

  static MessageType _typeFromString(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  bool get hasAttachment => attachmentUrl != null;
}