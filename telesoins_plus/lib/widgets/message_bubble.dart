import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/message.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.textSecondaryColor,
              backgroundImage: message.sender.profilePhotoUrl != null
                  ? NetworkImage(message.sender.profilePhotoUrl!)
                  : null,
              child: message.sender.profilePhotoUrl == null
                  ? Text(
                      _getInitials('${message.sender.firstName} ${message.sender.lastName}'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppTheme.primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isCurrentUser ? const Radius.circular(18) : const Radius.circular(0),
                  bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      '${message.sender.firstName} ${message.sender.lastName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCurrentUser ? Colors.white70 : AppTheme.primaryColor,
                      ),
                    ),
                  _buildMessageContent(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat.Hm().format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.attachmentUrl!,
                width: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 150,
                    width: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: 200,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
          ],
        );
      case MessageType.document:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isCurrentUser ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ],
        );
      case MessageType.audio:
        // Une implémentation simple pour l'audio
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack,
              color: isCurrentUser ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Message audio',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ],
        );
      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height:
                    150,
                    width: 200,
                    color: Colors.black,
                    child: message.attachmentUrl != null
                        ? Image.network(
                            message.attachmentUrl!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                Icon(
                  Icons.play_circle_fill,
                  size: 48,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
          ],
        );
    }
  }

  String _getInitials(String fullName) {
    List<String> names = fullName.split(' ');
    String initials = '';
    if (names.isNotEmpty) {
      initials += names[0][0];
      if (names.length > 1) {
        initials += names[names.length - 1][0];
      }
    }
    return initials.toUpperCase();
  }
}