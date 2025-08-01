import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/api_constants.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/main.dart';
import 'package:telesoins_plus/models/consultation.dart';
import 'package:telesoins_plus/services/api_service.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';

class MessagingScreen extends StatefulWidget {
  final String consultationId;

  const MessagingScreen({
    Key? key,
    required this.consultationId,
  }) : super(key: key);

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final ApiService _apiService = getIt<ApiService>();
  final AuthService _authService = getIt<AuthService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
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
    });

    try {
      // Charger les détails de la consultation
      final consultationResponse = await _apiService.get(
        '${ApiConstants.consultations}${widget.consultationId}/',
      );
      
      // Charger les messages
      final messagesResponse = await _apiService.get(
        '${ApiConstants.messages}by_consultation/?consultation_id=${widget.consultationId}',
      );

      if (mounted) {
        setState(() {
          _consultation = Consultation.fromJson(consultationResponse);
          _messages = (messagesResponse as List)
              .map((item) => Message.fromJson(item))
              .toList();
          _isLoading = false;
        });

        // Marquer tous les messages comme lus
        _markAllAsRead();

        // Défiler vers le bas pour voir les derniers messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiService.post(
        '${ApiConstants.messages}mark_all_as_read/',
        data: {'consultation': widget.consultationId},
      );
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final response = await _apiService.post(
        ApiConstants.messages,
        data: {
          'consultation': widget.consultationId,
          'content': message,
        },
      );

      if (mounted) {
        _messageController.clear();
        
        // Ajouter le nouveau message à la liste
        final newMessage = Message.fromJson(response);
        setState(() {
          _messages.add(newMessage);
          _isSending = false;
        });

        // Défiler vers le bas pour voir le nouveau message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi du message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Messagerie')
            : Text('Dr. ${_consultation!.medecin.lastName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Afficher les informations de la consultation
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
                // Afficher le statut de la consultation
                Container(
                  color: _consultation!.endTime != null
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.primaryLight,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _consultation!.endTime != null
                            ? Icons.check_circle_outline
                            : Icons.access_time,
                        color: _consultation!.endTime != null
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _consultation!.endTime != null
                              ? 'Consultation terminée le ${DateFormat('dd/MM/yyyy').format(_consultation!.endTime!)}'
                              : 'Consultation en cours',
                          style: TextStyle(
                            color: _consultation!.endTime != null
                                ? AppTheme.successColor
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun message dans cette conversation',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Envoyez votre premier message ci-dessous',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.sender.id ==
                                _authService.currentUser?.id;
                            
                            // Afficher la date si c'est le premier message ou si la date a changé
                            final showDate = index == 0 ||
                                DateFormat('yyyy-MM-dd').format(
                                        _messages[index].timestamp) !=
                                    DateFormat('yyyy-MM-dd').format(
                                        _messages[index - 1].timestamp);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDate)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          DateFormat('EEEE dd MMMM yyyy',
                                                  'fr_FR')
                                              .format(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.75),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppTheme.primaryColor
                                          : Colors.grey[200],
                                      borderRadius: BorderRadiusDirectional.only(
                                        topStart: Radius.circular(isMe ? 12 : 4),
                                        topEnd: Radius.circular(isMe ? 4 : 12),
                                        bottomStart: const Radius.circular(12),
                                        bottomEnd: const Radius.circular(12),
                                      ).resolve(Directionality.of(context)),
                                      ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('HH:mm')
                                              .format(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                // Zone de saisie du message
                Container(
                  padding: const EdgeInsets.all(8.0),
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
                          // Fonctionnalité d'attachement de fichier
                        },
                        color: Colors.grey[600],
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Tapez votre message...',
                            border: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 5,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : const Icon(Icons.send),
                        onPressed: _isSending ? null : _sendMessage,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}