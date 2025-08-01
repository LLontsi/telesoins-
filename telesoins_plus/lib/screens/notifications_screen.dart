import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/notification_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:telesoins_plus/models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  final String userType;
  
  const NotificationsScreen({Key? key, required this.userType}) : super(key: key);
  
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  String? _errorMessage;
  List<UserNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les notifications selon le type d'utilisateur
      final notifications = await _notificationService.getNotifications(userType: widget.userType);
      
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les notifications: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      setState(() {
        // Mettre à jour l'état de la notification dans la liste locale
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      setState(() {
        // Mettre à jour toutes les notifications dans la liste locale
        _notifications = _notifications.map((notification) => 
          notification.copyWith(isRead: true)
        ).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont été marquées comme lues'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_notifications.any((notification) => !notification.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tout marquer comme lu',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur de chargement',
                  details: _errorMessage,
                  onRetry: _loadNotifications,
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas de notifications pour le moment',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(UserNotification notification) {
    // Formater la date pour affichage
    final now = DateTime.now();
    final difference = now.difference(notification.createdAt);
    String timeAgo;
    
    if (difference.inMinutes < 60) {
      timeAgo = 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      timeAgo = 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      timeAgo = 'Il y a ${difference.inDays} j';
    } else {
      timeAgo = DateFormat.yMMMd('fr').format(notification.createdAt);
    }

    // Déterminer l'icône selon le type de notification
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.appointment:
        iconData = Icons.calendar_today;
        iconColor = AppTheme.medicalBlue;
        break;
      case NotificationType.message:
        iconData = Icons.message;
        iconColor = AppTheme.medicalGreen;
        break;
      case NotificationType.prescription:
        iconData = Icons.receipt;
        iconColor = AppTheme.primaryColor;
        break;
      case NotificationType.urgent:
        iconData = Icons.warning;
        iconColor = AppTheme.urgentColor;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppTheme.textSecondaryColor;
    }

    // Créer la carte pour la notification
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead 
            ? BorderSide.none 
            : BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          // Marquer comme lu si pas encore lu
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          
          // Naviguer vers l'écran approprié selon le type et la cible
          _navigateToTarget(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                    if (notification.targetType != null && notification.targetId != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              // Marquer comme lu si pas encore lu
                              if (!notification.isRead) {
                                _markAsRead(notification.id);
                              }
                              
                              // Naviguer vers l'écran approprié
                              _navigateToTarget(notification);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(_getActionText(notification.type)),
                          ),
                        ],
                      ),
                    ],
                    if (!notification.isRead) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionText(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return 'Voir le rendez-vous';
      case NotificationType.message:
        return 'Lire le message';
      case NotificationType.prescription:
        return 'Voir l\'ordonnance';
      case NotificationType.urgent:
        return 'Répondre';
      default:
        return 'Voir';
    }
  }

  void _navigateToTarget(UserNotification notification) {
    if (notification.targetType == null || notification.targetId == null) {
      return;
    }

    String route;
    
    switch (notification.targetType) {
      case 'appointment':
        route = widget.userType == 'medecin' 
            ? '/medecin/appointment_details' 
            : '/patient/appointment_details';
        break;
      case 'message':
        route = widget.userType == 'medecin' 
            ? '/medecin/messaging' 
            : '/patient/messaging';
        break;
      case 'prescription':
        route = widget.userType == 'medecin' 
            ? '/medecin/prescription_details' 
            : '/patient/prescription_details';
        break;
      case 'urgent':
        route = widget.userType == 'medecin' 
            ? '/medecin/urgent_consultation' 
            : '/patient/urgent_consultation';
        break;
      default:
        route = widget.userType == 'medecin' ? '/medecin/home' : '/patient/home';
    }
    
    Navigator.pushNamed(
      context,
      route,
      arguments: notification.targetId,
    );
  }
}