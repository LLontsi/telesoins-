
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isUserMessage;
  final VoidCallback? onAttachmentTap;
  final bool showTime;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUserMessage,
    this.onAttachmentTap,
    this.showTime = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeData = Theme.of(context);
    
    // Couleurs des bulles
    final userBubbleColor = themeData.primaryColor.withOpacity(0.9);
    final otherBubbleColor = themeData.colorScheme.secondary.withOpacity(0.2);
    
    // Format de la date et heure
    final timeFormat = DateFormat('HH:mm');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(maxWidth: size.width * 0.75),
        child: Column(
          crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUserMessage ? userBubbleColor : otherBubbleColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUserMessage) ...[
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUserMessage ? Colors.white : themeData.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUserMessage ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  if (message.hasAttachment) ...[
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: onAttachmentTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attachment,
                              size: 20,
                              color: isUserMessage ? Colors.white70 : Colors.black54,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pièce jointe',
                              style: TextStyle(
                                color: isUserMessage ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showTime) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  _isToday(message.timestamp) 
                      ? timeFormat.format(message.timestamp)
                      : dateTimeFormat.format(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Vérifier si la date est aujourd'hui
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day && 
           date.month == now.month && 
           date.year == now.year;
  }
}