import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/appointment.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/models/user.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailsScreen({
    Key? key,
    required this.appointmentId,
  }) : super(key: key);

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  bool _isLoading = false;
  String? _errorMessage;
  Appointment? _appointment;
  int? _consultationId;
  bool _isStartingConsultation = false;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Remplacer par un appel API réel
      // Simuler le chargement des données
      await Future.delayed(const Duration(seconds: 1));
      
      // Simuler un rendez-vous
      _appointment = Appointment(
        id: widget.appointmentId,
        patient: Patient(
          id: 1,
          email: 'patient@example.com',
          firstName: 'Prénom',
          lastName: 'Nom',
          phoneNumber: '+33 6 12 34 56 78',
        ),
        medecin: Medecin(
          id: 1,
          email: 'medecin@example.com',
          firstName: 'Dr.',
          lastName: 'Médecin',
          phoneNumber: '+33 6 98 76 54 32',
          speciality: 'Généraliste',
        ),
        dateTime: DateTime.now().add(const Duration(hours: 3)),
        status: AppointmentStatus.confirmed,
        reasonForVisit: 'Consultation de routine',
        isUrgent: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        appointmentType: 'video',
        notes: 'Apporter les derniers résultats d\'analyses',
      );
      
      // Simuler un ID de consultation si elle existe déjà
      _consultationId = null; // ou un ID réel si la consultation existe
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du rendez-vous: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startConsultation() async {
    if (_appointment == null) return;
    
    setState(() {
      _isStartingConsultation = true;
    });
    
    try {
      final consultation = await _consultationService.startConsultation(_appointment!.id);
      
      if (context.mounted) {
        // Naviguer vers l'écran de consultation
        Navigator.pushReplacementNamed(
          context,
          '/patient/consultation',
          arguments: consultation.id,
        );
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
        _isStartingConsultation = false;
      });
    }
  }

  Future<void> _cancelAppointment() async {
    if (_appointment == null) return;
    
    // Afficher une boîte de dialogue de confirmation
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    
    if (shouldCancel == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _consultationService.cancelAppointment(_appointment!.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendez-vous annulé avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = Provider.of<AuthService>(context).isPatient;
    final dateFormat = DateFormat.yMMMMd('fr');
    final timeFormat = DateFormat.Hm('fr');
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails du rendez-vous',
        type: isPatient ? AppBarType.patient : AppBarType.medecin,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur de chargement',
                  details: _errorMessage,
                  onRetry: _loadAppointment,
                )
              : _appointment == null
                  ? const Center(
                      child: Text('Rendez-vous introuvable'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête avec statut
                          _buildStatusHeader(),
                          const SizedBox(height: 16),
                          
                          // Carte avec les détails du rendez-vous
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Détails du rendez-vous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Divider(),
                                  _buildDetailItem(
                                    'Date',
                                    dateFormat.format(_appointment!.dateTime),
                                    Icons.calendar_today,
                                  ),
                                  _buildDetailItem(
                                    'Heure',
                                    timeFormat.format(_appointment!.dateTime),
                                    Icons.access_time,
                                  ),
                                  _buildDetailItem(
                                    'Type',
                                    _appointment!.appointmentTypeText,
                                    _getAppointmentTypeIcon(_appointment!.appointmentType),
                                  ),
                                  _buildDetailItem(
                                    isPatient ? 'Médecin' : 'Patient',
                                    isPatient
                                        ? 'Dr. ${_appointment!.medecin.lastName} - ${_appointment!.medecin.speciality ?? 'Médecin'}'
                                        : '${_appointment!.patient.firstName} ${_appointment!.patient.lastName}',
                                    Icons.person,
                                  ),
                                  if (_appointment!.reasonForVisit != null)
                                    _buildDetailItem(
                                      'Motif',
                                      _appointment!.reasonForVisit!,
                                      Icons.subject,
                                    ),
                                  if (_appointment!.notes != null)
                                    _buildDetailItem(
                                      'Notes',
                                      _appointment!.notes!,
                                      Icons.note,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Actions
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Actions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      if (_appointment!.status == AppointmentStatus.confirmed ||
                                          _appointment!.status == AppointmentStatus.pending)
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _cancelAppointment,
                                            icon: const Icon(Icons.cancel),
                                            label: const Text('Annuler'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.errorColor,
                                              side: const BorderSide(color: AppTheme.errorColor),
                                            ),
                                          ),
                                        ),
                                      if (_appointment!.status == AppointmentStatus.confirmed) ...[
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _isStartingConsultation 
                                                ? null 
                                                : _consultationId != null
                                                    ? () {
                                                        // Naviguer vers la consultation existante
                                                        Navigator.pushNamed(
                                                          context,
                                                          '/patient/consultation',
                                                          arguments: _consultationId,
                                                        );
                                                      }
                                                    : _startConsultation,
                                            icon: Icon(_consultationId != null 
                                                ? Icons.visibility 
                                                : Icons.video_call),
                                            label: Text(_consultationId != null 
                                                ? 'Voir consultation' 
                                                : 'Démarrer consultation'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _consultationId != null 
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Informations complémentaires (pour médecin uniquement)
                          if (!isPatient)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Informations patient',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Divider(),
                                    _buildDetailItem(
                                      'Téléphone',
                                      _appointment!.patient.phoneNumber,
                                      Icons.phone,
                                    ),
                                    _buildDetailItem(
                                      'Email',
                                      _appointment!.patient.email,
                                      Icons.email,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Naviguer vers le profil du patient
                                        Navigator.pushNamed(
                                          context,
                                          '/medecin/patient_details',
                                          arguments: _appointment!.patient.id,
                                        );
                                      },
                                      icon: const Icon(Icons.person),
                                      label: const Text('Voir profil complet'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusHeader() {
    if (_appointment == null) return const SizedBox.shrink();
    
    final statusColors = {
      AppointmentStatus.pending: AppTheme.warningColor,
      AppointmentStatus.confirmed: AppTheme.successColor,
      AppointmentStatus.inProgress: AppTheme.medicalBlue,
      AppointmentStatus.completed: AppTheme.primaryColor,
      AppointmentStatus.cancelled: AppTheme.errorColor,
      AppointmentStatus.missed: AppTheme.errorColor,
    };
    
    final statusColor = statusColors[_appointment!.status] ?? AppTheme.primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_appointment!.status),
            color: statusColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appointment!.statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(_appointment!.status),
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAppointmentTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'chat':
        return Icons.chat;
      case 'sms':
        return Icons.sms;
      default:
        return Icons.medical_services;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.pending;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.inProgress:
        return Icons.play_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.missed:
        return Icons.event_busy;
    }
  }

  String _getStatusDescription(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'En attente de confirmation par le médecin';
      case AppointmentStatus.confirmed:
        return 'Rendez-vous confirmé et prêt';
      case AppointmentStatus.inProgress:
        return 'Consultation en cours';
      case AppointmentStatus.completed:
        return 'Consultation terminée';
      case AppointmentStatus.cancelled:
        return 'Rendez-vous annulé';
      case AppointmentStatus.missed:
        return 'Rendez-vous manqué';
    }
  }
}