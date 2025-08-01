import 'package:telesoins_plus/models/notification.dart';
import 'package:telesoins_plus/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  // Récupérer la liste de notifications
  Future<List<UserNotification>> getNotifications({required String userType}) async {
    try {
      // Appel à l'API pour récupérer les notifications
      final response = await _apiService.get('/notifications?user_type=$userType');
      
      if (response.statusCode == 200) {
        final List<dynamic> notificationsJson = response.data['notifications'];
        return notificationsJson
            .map((json) => UserNotification.fromJson(json))
            .toList();
      } else {
        throw 'Erreur serveur: ${response.statusCode}';
      }
    } catch (e) {
      // Pour le développement/débogage, retourner des données fictives
      return _getMockNotifications(userType);
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.post('/notifications/$notificationId/read', data: {});
    } catch (e) {
      throw 'Erreur lors du marquage de la notification: $e';
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      await _apiService.post('/notifications/read-all', data: {});
    } catch (e) {
      throw 'Erreur lors du marquage de toutes les notifications: $e';
    }
  }

  // Données de test pour le développement
  List<UserNotification> _getMockNotifications(String userType) {
    final now = DateTime.now();
    
    if (userType == 'medecin') {
      return [
        UserNotification(
          id: '1',
          title: 'Nouveau rendez-vous',
          message: 'Marie Dupont a pris rendez-vous pour une consultation le 18 mars à 15h30.',
          createdAt: now.subtract(const Duration(hours: 2)),
          isRead: false,
          type: NotificationType.appointment,
          targetType: 'appointment',
          targetId: '123',
        ),
        UserNotification(
          id: '2',
          title: 'Message de patient',
          message: 'Jean Martin vous a envoyé un message concernant son traitement.',
          createdAt: now.subtract(const Duration(days: 1)),
          isRead: true,
          type: NotificationType.message,
          targetType: 'message',
          targetId: '456',
        ),
        UserNotification(
          id: '3',
          title: 'Consultation urgente',
          message: 'Un patient demande une consultation urgente pour des douleurs thoraciques.',
          createdAt: now.subtract(const Duration(minutes: 30)),
          isRead: false,
          type: NotificationType.urgent,
          targetType: 'urgent',
          targetId: '789',
        ),
      ];
    } else {
      // Notifications pour patient
      return [
        UserNotification(
          id: '1',
          title: 'Rappel de rendez-vous',
          message: 'Vous avez rendez-vous avec Dr. Martin demain à 10h30.',
          createdAt: now.subtract(const Duration(hours: 4)),
          isRead: false,
          type: NotificationType.appointment,
          targetType: 'appointment',
          targetId: '123',
        ),
        UserNotification(
          id: '2',
          title: 'Nouvelle ordonnance',
          message: 'Dr. Bernard vous a envoyé une nouvelle ordonnance.',
          createdAt: now.subtract(const Duration(days: 2)),
          isRead: true,
          type: NotificationType.prescription,
          targetType: 'prescription',
          targetId: '456',
        ),
        UserNotification(
          id: '3',
          title: 'Réponse à votre message',
          message: 'Dr. Martin a répondu à votre question sur les effets secondaires.',
          createdAt: now.subtract(const Duration(hours: 1)),
          isRead: false,
          type: NotificationType.message,
          targetType: 'message',
          targetId: '789',
        ),
      ];
    }
  }
}