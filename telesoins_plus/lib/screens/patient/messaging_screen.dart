import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/message.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/nav_drawer.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:telesoins_plus/widgets/message_bubble.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({Key? key}) : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Conversation> _conversations = [];
  Conversation? _selectedConversation;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // TODO: Appel API réel
      // Simulation pour l'exemple
      await Future.delayed(const Duration(seconds: 1));
      
      // Générer des conversations simulées
      final isPatient = Provider.of<AuthService>(context, listen: false).isPatient;
      
      _conversations = List.generate(
        5,
        (index) {
          final contact = isPatient
              ? Medecin(
                  id: index + 1,
                  email: 'medecin${index + 1}@example.com',
                  firstName: 'Dr.',
                  lastName: 'Médecin${index + 1}',
                  phoneNumber: '+33 6 12 34 56 78',
                  speciality: ['Généraliste', 'Cardiologue', 'Pédiatre', 'Dermatologue', 'Psychiatre'][index],
                )
              : Patient(
                  id: index + 1,
                  email: 'patient${index + 1}@example.com',
                  firstName: 'Prénom${index + 1}',
                  lastName: 'Nom${index + 1}',
                  phoneNumber: '+33 6 12 34 56 78',
                );
          
          return Conversation(
            id: index + 1,
            contact: contact,
            messages: _generateMessages(index + 1, contact),
            lastMessageTime: DateTime.now().subtract(Duration(hours: index * 3)),
            isRead: index > 1,
          );
        },
      );
      
      // Trier par date du dernier message
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les conversations: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<Message> _generateMessages(int conversationId, User contact) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 0;
    
    return List.generate(
      5 + conversationId, // Nombre de messages variable selon la conversation
      (index) {
        final isUserMessage = index % 2 == 0;
        final timestamp = DateTime.now().subtract(Duration(hours: index, minutes: 30 - index * 5));
        
        return Message(
          id: index + 1,
          consultationId: conversationId,
          sender: isUserMessage
              ? Provider.of<AuthService>(context, listen: false).currentUser!
              : contact,
          content: 'Message ${index + 1} de la conversation $conversationId. ${isUserMessage ? 'Envoyé par vous' : 'Reçu de ${contact.fullName}'}',
          type: MessageType.text,
          timestamp: timestamp,
          isRead: isUserMessage || timestamp.isBefore(DateTime.now().subtract(const Duration(hours: 1))),
        );
      },
    ).reversed.toList(); // Du plus récent au plus ancien
  }
  
  void _selectConversation(Conversation conversation) {
    setState(() {
      _selectedConversation = conversation;
      _selectedConversation!.isRead = true;
    });
    
    // Faire défiler vers le bas pour voir les messages les plus récents
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
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedConversation == null) {
      return;
    }
    
    setState(() {
      _isSending = true;
    });
    
    try {
      final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
      if (currentUser == null) return;
      
      // Simuler l'envoi d'un message
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newMessage = Message(
        id: _selectedConversation!.messages.length + 1,
        consultationId: _selectedConversation!.id,
        sender: currentUser,
        content: _messageController.text.trim(),
        type: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      setState(() {
        _selectedConversation!.messages.add(newMessage);
        _selectedConversation!.lastMessageTime = newMessage.timestamp;
        _messageController.clear();
      });
      
      // Faire défiler vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      // Mettre à jour l'ordre des conversations
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
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

  @override
  Widget build(BuildContext context) {
    final isPatient = Provider.of<AuthService>(context).isPatient;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Messages',
        type: isPatient ? AppBarType.patient : AppBarType.medecin,
      ),
      drawer: const NavDrawer(activeRoute: '/patient/messaging'),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur de chargement',
                  details: _errorMessage,
                  onRetry: _loadConversations,
                )
              : Row(
                  children: [
                    // Liste des conversations (largeur variable selon l'espace disponible)
                    Container(
                      width: _selectedConversation != null && MediaQuery.of(context).size.width > 600
                          ? MediaQuery.of(context).size.width * 0.3
                          : MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: _conversations.isEmpty
                          ? const Center(
                              child: Text('Aucune conversation'),
                            )
                          : ListView.separated(
                              itemCount: _conversations.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final conversation = _conversations[index];
                                return _buildConversationTile(conversation);
                              },
                            ),
                    ),
                    
                    // Écran de conversation (visible uniquement sur écrans larges ou si une conversation est sélectionnée)
                    if (_selectedConversation != null && MediaQuery.of(context).size.width > 600)
                      Expanded(
                        child: _buildConversationScreen(),
                      ),
                  ],
                ),
    );
  }
  
  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = _selectedConversation?.id == conversation.id;
    final lastMessage = conversation.messages.isNotEmpty ? conversation.messages.last : null;
    final formattedTime = _formatTime(conversation.lastMessageTime);
    
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
      leading: CircleAvatar(
        backgroundColor: conversation.isRead 
            ? Colors.grey.shade300 
            : AppTheme.primaryColor,
        backgroundImage: conversation.contact.profilePhotoUrl != null
            ? NetworkImage(conversation.contact.profilePhotoUrl!)
            : null,
        child: conversation.contact.profilePhotoUrl == null
            ? Text(
                _getInitials(conversation.contact.fullName),
                style: TextStyle(
                  color: conversation.isRead 
                      ? AppTheme.textPrimaryColor 
                      : Colors.white,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.contact.fullName,
              style: TextStyle(
                fontWeight: conversation.isRead ? FontWeight.normal : FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: conversation.isRead 
                  ? AppTheme.textSecondaryColor 
                  : AppTheme.primaryColor,
              fontWeight: conversation.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.contact is Medecin)
            Text(
              '${(conversation.contact as Medecin).speciality ?? 'Médecin'} • ',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          Expanded(
            child: Text(
              lastMessage?.content ?? 'Pas de message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.isRead 
                    ? AppTheme.textSecondaryColor 
                    : AppTheme.textPrimaryColor,
              ),
            ),
          ),
          if (!conversation.isRead)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
      onTap: () {
        if (MediaQuery.of(context).size.width <= 600) {
          // Sur petit écran, naviguer vers une nouvelle page
          _selectConversation(conversation);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: conversation,
                onSendMessage: _sendMessage,
                isSending: _isSending,
                messageController: _messageController,
                scrollController: _scrollController,
              ),
            ),
          );
        } else {
          // Sur grand écran, afficher la conversation à côté
          _selectConversation(conversation);
        }
      },
    );
  }
  
  Widget _buildConversationScreen() {
    if (_selectedConversation == null) {
      return const Center(
        child: Text('Sélectionnez une conversation'),
      );
    }
    
    return Column(
      children: [
        // En-tête avec les informations du contact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                backgroundImage: _selectedConversation!.contact.profilePhotoUrl != null
                    ? NetworkImage(_selectedConversation!.contact.profilePhotoUrl!)
                    : null,
                child: _selectedConversation!.contact.profilePhotoUrl == null
                    ? Text(
                        _getInitials(_selectedConversation!.contact.fullName),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedConversation!.contact.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_selectedConversation!.contact is Medecin)
                      Text(
                        (_selectedConversation!.contact as Medecin).speciality ?? 'Médecin',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Afficher les détails du contact
                },
              ),
            ],
          ),
        ),
        
        // Liste des messages
        Expanded(
          child: _selectedConversation!.messages.isEmpty
              ? const Center(
                  child: Text('Pas encore de messages'),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedConversation!.messages.length,
                  itemBuilder: (context, index) {
                    final message = _selectedConversation!.messages[index];
                    final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.id;
                    final isUserMessage = message.sender.id == currentUserId;
                    
                    return MessageBubble(
                      message: message,
                      isCurrentUser: isUserMessage,
                    );
                  },
                ),
        ),
        
        // Zone de saisie du message
        Container(
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
                  // TODO: Ajout de pièces jointes
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
        ),
      ],
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return DateFormat.Hm().format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat.E('fr').format(dateTime);
    } else {
      return DateFormat.yMd('fr').format(dateTime);
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

class Conversation {
  final int id;
  final User contact;
  final List<Message> messages;
  DateTime lastMessageTime;
  bool isRead;
  
  Conversation({
    required this.id,
    required this.contact,
    required this.messages,
    required this.lastMessageTime,
    this.isRead = false,
  });
}

class ConversationPage extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onSendMessage;
  final bool isSending;
  final TextEditingController messageController;
  final ScrollController scrollController;
  
  const ConversationPage({
    Key? key,
    required this.conversation,
    required this.onSendMessage,
    required this.isSending,
    required this.messageController,
    required this.scrollController,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 16,
              backgroundImage: conversation.contact.profilePhotoUrl != null
                  ? NetworkImage(conversation.contact.profilePhotoUrl!)
                  : null,
              child: conversation.contact.profilePhotoUrl == null
                  ? Text(
                      _getInitials(conversation.contact.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.contact.fullName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (conversation.contact is Medecin)
                    Text(
                      (conversation.contact as Medecin).speciality ?? 'Médecin',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: conversation.messages.isEmpty
                ? const Center(
                    child: Text('Pas encore de messages'),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) {
                      final message = conversation.messages[index];
                      final currentUserId = Provider.of<AuthService>(context, listen: false).currentUser?.id;
                      final isUserMessage = message.sender.id == currentUserId;
                      
                      return MessageBubble(
                        message: message,
                        isCurrentUser: isUserMessage,
                      );
                    },
                  ),
          ),
          
          // Zone de saisie du message
          Container(
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
                    // TODO: Ajout de pièces jointes
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    onSubmitted: (_) => onSendMessage(),
                  ),
                ),
                isSending
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
                        onPressed: onSendMessage,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
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