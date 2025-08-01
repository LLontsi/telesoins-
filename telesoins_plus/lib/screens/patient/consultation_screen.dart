import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/consultation.dart';
import 'package:telesoins_plus/models/message.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:telesoins_plus/widgets/message_bubble.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ConsultationScreen extends StatefulWidget {
  final int consultationId;

  const ConsultationScreen({
    Key? key,
    required this.consultationId,
  }) : super(key: key);

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  Consultation? _consultation;
  List<Message> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _loadConsultation();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadConsultation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final consultation = await _consultationService.getConsultation(widget.consultationId);
      setState(() {
        _consultation = consultation;
        _messages = consultation.messages;
      });
      
      // Faire défiler vers le bas après avoir chargé les messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger la consultation: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      final message = await _consultationService.sendMessage(
        widget.consultationId,
        {
          'content': _messageController.text.trim(),
          'type': 'text',
        },
      );
      
      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
      
      // Faire défiler vers le bas après avoir envoyé un message
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: _consultation != null 
            ? 'Consultation avec ${currentUser?.userType == 'patient' ? 'Dr. ${_consultation!.appointment.medecin.lastName}' : _consultation!.appointment.patient.fullName}'
            : 'Consultation',
        type: currentUser?.userType == 'patient' ? AppBarType.patient : AppBarType.medecin,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Afficher les détails de la consultation
              _showConsultationDetails();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur de chargement',
                  details: _errorMessage,
                  onRetry: _loadConsultation,
                )
              : Column(
                  children: [
                    // En-tête de consultation
                    _buildConsultationHeader(),
                    // Messages
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun message dans cette consultation',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isCurrentUser = message.sender.id == currentUser?.id;
                                return MessageBubble(
                                  message: message,
                                  isCurrentUser: isCurrentUser,
                                );
                              },
                            ),
                    ),
                    // Zone de saisie du message
                    if (_consultation?.status == ConsultationStatus.inProgress)
                      _buildMessageInput(),
                  ],
                ),
    );
  }
  
  Widget _buildConsultationHeader() {
    if (_consultation == null) return const SizedBox();
    
    final statusColors = {
      ConsultationStatus.scheduled: AppTheme.warningColor,
      ConsultationStatus.inProgress: AppTheme.medicalBlue,
      ConsultationStatus.completed: AppTheme.successColor,
      ConsultationStatus.cancelled: AppTheme.errorColor,
    };
    
    final statusColor = statusColors[_consultation!.status] ?? AppTheme.primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_consultation!.status),
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut: ${_consultation!.statusText}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  'Début: ${DateFormat.yMd('fr').add_Hm().format(_consultation!.startTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (_consultation!.status == ConsultationStatus.inProgress)
            OutlinedButton(
              onPressed: () {
                // Démarrer un appel vidéo
                _startVideoCall();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.medicalBlue,
                side: const BorderSide(color: AppTheme.medicalBlue),
              ),
              child: const Text('Appel vidéo'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implémenter l'ajout de pièces jointes
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Tapez votre message...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          _isSending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  color: AppTheme.primaryColor,
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }
  
  void _showConsultationDetails() {
    if (_consultation == null) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Détails de la consultation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildDetailItem('Date', DateFormat.yMMMMd('fr').format(_consultation!.startTime)),
              _buildDetailItem('Heure', DateFormat.Hm('fr').format(_consultation!.startTime)),
              _buildDetailItem('Durée', _consultation!.endTime != null
                  ? '${_consultation!.durationInMinutes} minutes'
                  : 'En cours'),
              _buildDetailItem('Type', _consultation!.appointment.appointmentTypeText),
              if (_consultation!.diagnosis != null)
                _buildDetailItem('Diagnostic', _consultation!.diagnosis!),
              if (_consultation!.treatmentPlan != null)
                _buildDetailItem('Plan de traitement', _consultation!.treatmentPlan!),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
 IconData _getStatusIcon(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.scheduled:
        return Icons.schedule;
      case ConsultationStatus.inProgress:
        return Icons.play_circle_fill;
      case ConsultationStatus.completed:
        return Icons.check_circle;
      case ConsultationStatus.cancelled:
        return Icons.cancel;
    }
  }
  
  void _startVideoCall() {
    // TODO: Implémenter l'appel vidéo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction d\'appel vidéo non implémentée'),
      ),
    );
  }
}