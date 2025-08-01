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
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ConsultationScreen extends StatefulWidget {
  final int consultationId;

  const ConsultationScreen({
    Key? key,
    required this.consultationId,
  }) : super(key: key);

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> with SingleTickerProviderStateMixin {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  Consultation? _consultation;
  List<Message> _messages = [];
  bool _isConsultationEnding = false;
  File? _attachmentFile;
  late TabController _tabController;
  
  // Contrôleurs pour le résumé de consultation
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _treatmentPlanController = TextEditingController();
  final TextEditingController _followUpInstructionsController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConsultation();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _diagnosisController.dispose();
    _treatmentPlanController.dispose();
    _followUpInstructionsController.dispose();
    _tabController.dispose();
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
        
        // Initialiser les champs du résumé si disponibles
        _diagnosisController.text = consultation.diagnosis ?? '';
        _treatmentPlanController.text = consultation.treatmentPlan ?? '';
        _followUpInstructionsController.text = consultation.followUpInstructions ?? '';
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
    if (_messageController.text.trim().isEmpty && _attachmentFile == null) {
      return;
    }
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // Préparer les données du message
      final messageData = {
        'content': _messageController.text.trim(),
        'type': _attachmentFile != null 
            ? _getMessageTypeFromFile(_attachmentFile!) 
            : 'text',
      };
      
      // TODO: Gérer l'envoi des pièces jointes avec l'API réelle
      
      final message = await _consultationService.sendMessage(
        widget.consultationId,
        messageData,
      );
      
      setState(() {
        _messages.add(message);
        _messageController.clear();
        _attachmentFile = null;
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
  
  String _getMessageTypeFromFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi'].contains(extension)) {
      return 'video';
    } else if (['mp3', 'wav', 'm4a'].contains(extension)) {
      return 'audio';
    } else {
      return 'document';
    }
  }
  
  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.file_present),
                title: const Text('Document'),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        );
      },
    );
    
    if (source == null) {
      // Sélection de document (non implémenté ici, nécessiterait un package supplémentaire)
      return;
    }
    
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachmentFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
  
  Future<void> _endConsultation() async {
    if (_consultation == null) return;
    
    // Vérifier si les champs obligatoires sont remplis
    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un diagnostic'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isConsultationEnding = true;
    });
    
    try {
      // Préparer les données de résumé
      final summaryData = {
        'diagnosis': _diagnosisController.text.trim(),
        'treatment_plan': _treatmentPlanController.text.trim(),
        'follow_up_instructions': _followUpInstructionsController.text.trim(),
      };
      
      // Terminer la consultation
      final updatedConsultation = await _consultationService.endConsultation(
        widget.consultationId,
        summaryData,
      );
      
     /* setState(() {
        _consultation = updatedConsultation;
      });*/
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation terminée avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context); // Retour à l'écran précédent
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isConsultationEnding = false;
      });
    }
  }
  
  void _createPrescription() {
    if (_consultation == null) return;
    
    Navigator.pushNamed(
      context,
      '/medecin/new_prescription',
      arguments: _consultation!.appointment.patient.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final patient = _consultation?.appointment.patient;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: patient != null ? 'Consultation - ${patient.fullName}' : 'Consultation',
        type: AppBarType.medecin,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Créer ordonnance',
            onPressed: _consultation?.status != ConsultationStatus.completed 
                ? _createPrescription 
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Détails de la consultation',
            onPressed: () {
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
                    // En-tête du patient
                    if (patient != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: AppTheme.medicalBlue.withOpacity(0.1),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.medicalBlue,
                              child: Text(
                                _getInitials(patient.fullName),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (patient.dateOfBirth != null)
                                    Text(
                                      '${DateTime.now().year - patient.dateOfBirth!.year} ans',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_consultation?.status == ConsultationStatus.inProgress)
                              OutlinedButton.icon(
                                onPressed: () {
                                  _tabController.animateTo(1); // Aller à l'onglet de résumé
                                },
                                icon: const Icon(Icons.medical_services),
                                label: const Text('Fiche médicale'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.medicalBlue,
                                ),
                              ),
                          ],
                        ),
                      ),
                    
                    // Onglets (messages et résumé)
                    if (_consultation?.status == ConsultationStatus.inProgress)
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.medicalBlue,
                        unselectedLabelColor: AppTheme.textSecondaryColor,
                        indicatorColor: AppTheme.medicalBlue,
                        tabs: const [
                          Tab(text: 'Consultation'),
                          Tab(text: 'Résumé médical'),
                        ],
                      ),
                    
                    // Contenu des onglets
                    Expanded(
                      child: _consultation?.status == ConsultationStatus.inProgress
                          ? TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMessagesTab(currentUser?.id),
                                _buildSummaryTab(),
                              ],
                            )
                          : _buildMessagesTab(currentUser?.id),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildMessagesTab(int? currentUserId) {
    return Column(
      children: [
        // Corps des messages
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
                    final isCurrentUser = message.sender.id == currentUserId;
                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
        ),
        
        // Prévisualisation de la pièce jointe
        if (_attachmentFile != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.file(
                      _attachmentFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.insert_drive_file,
                        size: 40,
                        color: AppTheme.medicalBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _attachmentFile!.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _attachmentFile = null;
                    });
                  },
                ),
              ],
            ),
          ),
        
        // Zone de saisie du message
        if (_consultation?.status == ConsultationStatus.inProgress)
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
                  onPressed: _pickAttachment,
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
                  icon: const Icon(Icons.videocam),
                  color: AppTheme.medicalBlue,
                  onPressed: () {
                    // TODO: Implémentation d'appel vidéo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonction d\'appel vidéo non implémentée'),
                      ),
                    );
                  },
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
                        color: AppTheme.medicalBlue,
                        onPressed: _sendMessage,
                      ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé médical',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Diagnostic
          TextField(
            controller: _diagnosisController,
            decoration: const InputDecoration(
              labelText: 'Diagnostic *',
              border: OutlineInputBorder(),
              hintText: 'Entrez le diagnostic pour ce patient',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Plan de traitement
          TextField(
            controller: _treatmentPlanController,
            decoration: const InputDecoration(
              labelText: 'Plan de traitement',
              border: OutlineInputBorder(),
              hintText: 'Décrivez le plan de traitement recommandé',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Instructions de suivi
          TextField(
            controller: _followUpInstructionsController,
            decoration: const InputDecoration(
              labelText: 'Instructions de suivi',
              border: OutlineInputBorder(),
              hintText: 'Consignes à donner au patient pour le suivi',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          
          // Actions de consultation
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _createPrescription();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('CRÉER ORDONNANCE'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isConsultationEnding ? null : _endConsultation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.medicalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isConsultationEnding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('TERMINER CONSULTATION'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showConsultationDetails() {
    if (_consultation == null) return;
    
    final dateFormat = DateFormat.yMMMMd('fr');
    final timeFormat = DateFormat.Hm('fr');
    
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
              _buildDetailItem('Patient', _consultation!.appointment.patient.fullName),
              _buildDetailItem('Date', dateFormat.format(_consultation!.startTime)),
              _buildDetailItem('Heure', timeFormat.format(_consultation!.startTime)),
              _buildDetailItem('Statut', _consultation!.statusText),
              _buildDetailItem('Type', _consultation!.appointment.appointmentTypeText),
              if (_consultation!.appointment.reasonForVisit != null)
                _buildDetailItem('Motif', _consultation!.appointment.reasonForVisit!),
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
            width: 100,
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