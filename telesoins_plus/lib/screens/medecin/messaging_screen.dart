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

class MedecinMessagingScreen extends StatefulWidget {
  const MedecinMessagingScreen({Key? key}) : super(key: key);

  @override
  State<MedecinMessagingScreen> createState() => _MedecinMessagingScreenState();
}

class _MedecinMessagingScreenState extends State<MedecinMessagingScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Patient> _patients = [];
  List<Conversation> _conversations = [];
  Conversation? _selectedConversation;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  @override
  void initState() {
    super.initState();
    _loadPatientsAndConversations();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPatientsAndConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // TODO: Appel API réel pour charger les patients du médecin
      // Simulation pour l'exemple
      await Future.delayed(const Duration(seconds: 1));
      
      // Générer des patients simulés
      _patients = List.generate(
        10,
        (index) => Patient(
          id: index + 1,
          email: 'patient${index + 1}@example.com',
          firstName: 'Prénom${index + 1}',
          lastName: 'Nom${index + 1}',
          phoneNumber: '+33 6 12 34 56 ${index + 10}',
          dateOfBirth: DateTime.now().subtract(Duration(days: 365 * (20 + index))),
        ),
      );
      
      // Générer des conversations avec un sous-ensemble de patients
      _conversations = List.generate(
        5,
        (index) {
          final patient = _patients[index];
          
          return Conversation(
            id: index + 1,
            contact: patient,
            messages: _generateMessages(index + 1, patient),
            lastMessageTime: DateTime.now().subtract(Duration(hours: index * 3)),
            isRead: index > 1,
          );
        },
      );
      
      // Trier par date du dernier message
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les patients: ${e.toString()}';
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
  
  Future<void> _startNewConversation(Patient patient) async {
    // Vérifier si une conversation existe déjà avec ce patient
    final existingConversation = _conversations.firstWhere(
      (c) => c.contact.id == patient.id,
      orElse: () => Conversation(
        id: _conversations.length + 1,
        contact: patient,
        messages: [],
        lastMessageTime: DateTime.now(),
        isRead: true,
      ),
    );
    
    if (!_conversations.contains(existingConversation)) {
      setState(() {
        _conversations.add(existingConversation);
      });
    }
    
    _selectConversation(existingConversation);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messagerie',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Fonctionnalité de recherche de patients
            },
          ),
        ],
      ),
      drawer: const NavDrawer(activeRoute: '/medecin/messaging'),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur de chargement',
                  details: _errorMessage,
                  onRetry: _loadPatientsAndConversations,
                )
              : Row(
                  children: [
                    // Liste des patients et conversations
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
                      child: Column(
                        children: [
                          // Onglets pour basculer entre Conversations et Patients
                          Material(
                            color: Colors.white,
                            elevation: 2,
                            child: TabBar(
                              tabs: const [
                                Tab(text: 'Conversations'),
                                Tab(text: 'Tous les patients'),
                              ],
                              indicatorColor: AppTheme.primaryColor,
                              labelColor: AppTheme.primaryColor,
                              unselectedLabelColor: AppTheme.textSecondaryColor,
                              onTap: (index) {
                                // Changer l'onglet actif
                              },
                            ),
                          ),
                          
                          // Liste des conversations actives
                          Expanded(
                            child: _conversations.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.message_outlined,
                                          size: 64,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Aucune conversation active',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            // Basculer vers l'onglet "Tous les patients"
                                          },
                                          icon: const Icon(Icons.person_add),
                                          label: const Text('Contacter un patient'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
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
                        ],
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
    final patient = conversation.contact as Patient;
    
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: conversation.isRead 
                ? Colors.grey.shade300 
                : AppTheme.primaryColor,
            backgroundImage: patient.profilePhotoUrl != null
                ? NetworkImage(patient.profilePhotoUrl!)
                : null,
            child: patient.profilePhotoUrl == null
                ? Text(
                    _getInitials(patient.fullName),
                    style: TextStyle(
                      color: conversation.isRead 
                          ? AppTheme.textPrimaryColor 
                          : Colors.white,
                    ),
                  )
                : null,
          ),

        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              patient.fullName,
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
          // Afficher l'âge du patient
          if (patient.dateOfBirth != null)
            Text(
              '${_calculateAge(patient.dateOfBirth!)} ans • ',
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
  
  Widget _buildPatientTile(Patient patient) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        backgroundImage: patient.profilePhotoUrl != null
            ? NetworkImage(patient.profilePhotoUrl!)
            : null,
        child: patient.profilePhotoUrl == null
            ? Text(
                _getInitials(patient.fullName),
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(
        patient.fullName,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        patient.dateOfBirth != null
            ? '${_calculateAge(patient.dateOfBirth!)} ans'
            : 'Patient',
        style: const TextStyle(
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.message_outlined,
          color: AppTheme.primaryColor,
        ),
        onPressed: () => _startNewConversation(patient),
      ),
      onTap: () => _startNewConversation(patient),
    );
  }
  
  Widget _buildConversationScreen() {
    if (_selectedConversation == null) {
      return const Center(
        child: Text('Sélectionnez une conversation'),
      );
    }
    
    final patient = _selectedConversation!.contact as Patient;
    
    return Column(
      children: [
        // En-tête avec les informations du patient
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
                backgroundImage: patient.profilePhotoUrl != null
                    ? NetworkImage(patient.profilePhotoUrl!)
                    : null,
                child: patient.profilePhotoUrl == null
                    ? Text(
                        _getInitials(patient.fullName),
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
                      patient.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      patient.dateOfBirth != null
                          ? '${_calculateAge(patient.dateOfBirth!)} ans'
                          : 'Patient',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Dossier'),
                    onPressed: () {
                      // Naviguer vers le dossier médical du patient
                      Navigator.pushNamed(
                        context,
                        '/medecin/patient_details',
                        arguments: patient.id,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.video_call),
                    onPressed: () {
                      // Démarrer un appel vidéo
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Liste des messages
        Expanded(
          child: _selectedConversation!.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Commencez la conversation avec ce patient',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
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
              IconButton(
                icon: const Icon(Icons.medication),
                color: AppTheme.medicalBlue,
                tooltip: 'Prescription',
                onPressed: () {
                  // Naviguer vers la création d'ordonnance
                  Navigator.pushNamed(
                    context,
                    '/medecin/new_prescription',
                    arguments: (patient as Patient).id,
                  );
                },
              ),
              const SizedBox(width: 8),
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
  
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

// Classe pour la page de conversation sur petit écran
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
    final patient = conversation.contact as Patient;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 16,
              backgroundImage: patient.profilePhotoUrl != null
                  ? NetworkImage(patient.profilePhotoUrl!)
                  : null,
              child: patient.profilePhotoUrl == null
                  ? Text(
                      _getInitials(patient.fullName),
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
                    patient.fullName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (patient.dateOfBirth != null)
                    Text(
                      '${_calculateAge(patient.dateOfBirth!)} ans',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              // Démarrer un appel vidéo
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Afficher les détails du patient
              Navigator.pushNamed(
                context,
                '/medecin/patient_details',
                arguments: patient.id,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: conversation.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Commencez la conversation avec ce patient',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
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
                IconButton(
                  icon: const Icon(Icons.medication),
                  color: AppTheme.medicalBlue,
                  tooltip: 'Prescription',
                  onPressed: () {
                    // Naviguer vers la création d'ordonnance
                    Navigator.pushNamed(
                      context,
                      '/medecin/new_prescription',
                      arguments: patient.id,
                    );
                  },
                ),
                const SizedBox(width: 8),
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
  
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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