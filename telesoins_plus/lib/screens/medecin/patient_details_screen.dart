import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/appointment.dart';
import 'package:telesoins_plus/models/prescription.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:telesoins_plus/widgets/appointment_card.dart';

class PatientDetailsScreen extends StatefulWidget {
  final int patientId;

  const PatientDetailsScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  final ConsultationService _consultationService = ConsultationService();
  bool _isLoading = false;
  String? _errorMessage;
  Patient? _patient;
  List<Appointment> _appointments = [];
  List<Prescription> _prescriptions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Remplacer par des appels API réels
      // Simulation de données pour l'exemple
      await Future.delayed(const Duration(seconds: 1));
      
      // Simuler les données du patient
      _patient = Patient(
        id: widget.patientId,
        email: 'patient${widget.patientId}@example.com',
        firstName: 'Prénom',
        lastName: 'Nom',
        phoneNumber: '+33 6 12 34 56 78',
        dateOfBirth: DateTime(1985, 5, 15),
        address: '12 rue de la Santé, 75000 Paris',
        bloodGroup: 'A+',
        allergies: ['Pénicilline', 'Pollen'],
        chronicConditions: ['Hypertension'],
      );
      
      // Simuler les rendez-vous
      _appointments = List.generate(
        5,
        (index) => Appointment(
          id: index + 1,
          patient: _patient!,
          medecin: Medecin(
            id: 1,
            email: 'medecin@example.com',
            firstName: 'Dr.',
            lastName: 'Médecin',
            phoneNumber: '+33 6 98 76 54 32',
            speciality: 'Généraliste',
          ),
          dateTime: DateTime.now().add(Duration(days: index - 2)),
          status: index < 2 
              ? AppointmentStatus.completed 
              : index == 2 
                  ? AppointmentStatus.inProgress 
                  : AppointmentStatus.confirmed,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          appointmentType: ['video', 'chat', 'sms'][index % 3],
        ),
      );
      
      // Simuler les ordonnances
      _prescriptions = List.generate(
        3,
        (index) => Prescription(
          id: index + 1,
          patient: _patient!,
          medecin: Medecin(
            id: 1,
            email: 'medecin@example.com',
            firstName: 'Dr.',
            lastName: 'Médecin',
            phoneNumber: '+33 6 98 76 54 32',
            speciality: 'Généraliste',
          ),
          issueDate: DateTime.now().subtract(Duration(days: index * 30)),
          expiryDate: DateTime.now().add(Duration(days: (3 - index) * 30 - 1)),
          medications: List.generate(
            2 + index,
            (medIndex) => Medication(
              name: 'Médicament ${medIndex + 1}',
              dosage: '${(medIndex + 1) * 100}mg',
              frequency: '${medIndex + 1}x par jour',
              durationDays: (medIndex + 1) * 7,
            ),
          ),
          diagnosis: 'Diagnostic exemple ${index + 1}',
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _patient != null ? '${_patient!.firstName} ${_patient!.lastName}' : 'Détails du patient',
        type: AppBarType.medecin,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur de chargement',
                  details: _errorMessage,
                  onRetry: _loadPatientData,
                )
              : _patient == null
                  ? const Center(
                      child: Text('Patient introuvable'),
                    )
                  : Column(
                      children: [
                        // Informations du patient
                        _buildPatientHeader(),
                        // Tabs
                        TabBar(
                          controller: _tabController,
                          labelColor: AppTheme.medicalBlue,
                          unselectedLabelColor: AppTheme.textSecondaryColor,
                          indicatorColor: AppTheme.medicalBlue,
                          tabs: const [
                            Tab(text: 'Informations'),
                            Tab(text: 'Rendez-vous'),
                            Tab(text: 'Ordonnances'),
                          ],
                        ),
                        // Contenu des tabs
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Onglet des informations
                              _buildPatientInfoTab(),
                              // Onglet des rendez-vous
                              _buildAppointmentsTab(),
                              // Onglet des ordonnances
                              _buildPrescriptionsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Naviguer vers l'écran de création d'ordonnance
          Navigator.pushNamed(
            context,
            '/medecin/new_prescription',
            arguments: _patient?.id,
          );
        },
        backgroundColor: AppTheme.medicalBlue,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle ordonnance'),
      ),
    );
  }

  Widget _buildPatientHeader() {
    if (_patient == null) return const SizedBox.shrink();
    
    final ageYears = DateTime.now().difference(_patient!.dateOfBirth!).inDays ~/ 365;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.medicalBlue.withOpacity(0.1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.medicalBlue,
            backgroundImage: _patient!.profilePhotoUrl != null
                ? NetworkImage(_patient!.profilePhotoUrl!)
                : null,
            child: _patient!.profilePhotoUrl == null
                ? Text(
                    _getInitials('${_patient!.firstName} ${_patient!.lastName}'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_patient!.firstName} ${_patient!.lastName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ageYears ans • ${_patient!.bloodGroup}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 16,
                      color: AppTheme.medicalBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _patient!.phoneNumber,
                      style: const TextStyle(
                        color: AppTheme.medicalBlue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.message),
                color: AppTheme.medicalBlue,
                onPressed: () {
                  // TODO: Naviguer vers la messagerie
                },
              ),
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.medicalBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoTab() {
    if (_patient == null) return const SizedBox.shrink();
    
    final dateFormat = DateFormat.yMMMMd('fr');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: 'Informations personnelles',
            icon: Icons.person,
            children: [
              _buildInfoItem('Date de naissance', dateFormat.format(_patient!.dateOfBirth!)),
              _buildInfoItem('Adresse e-mail', _patient!.email),
              _buildInfoItem('Adresse', _patient!.address ?? 'Non renseignée'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            title: 'Informations médicales',
            icon: Icons.medical_services,
            children: [
              _buildInfoItem('Groupe sanguin', _patient!.bloodGroup ?? 'Non renseigné'),
              _buildInfoItem(
                'Allergies', 
                _patient!.allergies != null && _patient!.allergies!.isNotEmpty
                    ? _patient!.allergies!.join(', ')
                    : 'Aucune allergie connue',
              ),
              _buildInfoItem(
                'Maladies chroniques', 
                _patient!.chronicConditions != null && _patient!.chronicConditions!.isNotEmpty
                    ? _patient!.chronicConditions!.join(', ')
                    : 'Aucune maladie chronique connue',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            title: 'Dernières consultations',
            icon: Icons.calendar_today,
            children: _appointments
                .where((appointment) => 
                    appointment.status == AppointmentStatus.completed ||
                    appointment.status == AppointmentStatus.inProgress)
                .take(3)
                .map((appointment) => _buildInfoItem(
                  dateFormat.format(appointment.dateTime), 
                  appointment.reasonForVisit ?? 'Consultation générale',
                ))
                .toList(),
          ),
          const SizedBox(height: 16),
          // Notes du médecin
          _buildInfoSection(
            title: 'Notes médicales',
            icon: Icons.note,
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // TODO: Éditer les notes
              },
            ),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Pas de notes médicales pour ce patient.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return _appointments.isEmpty
        ? const Center(
            child: Text(
              'Aucun rendez-vous trouvé',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _appointments.length,
            itemBuilder: (context, index) {
              final appointment = _appointments[index];
              return AppointmentCard(
                appointment: appointment,
                isPatientView: false,
                onTap: () {
                  // Naviguer vers les détails du rendez-vous
                  Navigator.pushNamed(
                    context,
                    '/medecin/appointment_details',
                    arguments: appointment.id,
                  );
                },
              );
            },
          );
  }

  Widget _buildPrescriptionsTab() {
    return _prescriptions.isEmpty
        ? const Center(
            child: Text(
              'Aucune ordonnance trouvée',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _prescriptions.length,
            itemBuilder: (context, index) {
              final prescription = _prescriptions[index];
              final dateFormat = DateFormat.yMMMMd('fr');
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    // Naviguer vers les détails de l'ordonnance
                    Navigator.pushNamed(
                      context,
                      '/medecin/prescription_details',
                      arguments: prescription.id,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFormat.format(prescription.issueDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: prescription.isExpired 
                                    ? Colors.grey
                                    : AppTheme.successColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                prescription.isExpired ? 'Expirée' : 'Active',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (prescription.diagnosis != null)
                          Text(
                            'Diagnostic: ${prescription.diagnosis}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 8),
                        ...prescription.medications.map((medication) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.medication,
                                  size: 16,
                                  color: AppTheme.medicalBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${medication.name} - ${medication.dosage} - ${medication.frequency}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                // Éditer l'ordonnance
                                Navigator.pushNamed(
                                  context,
                                  '/medecin/edit_prescription',
                                  arguments: prescription.id,
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Éditer'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Voir les détails
                                Navigator.pushNamed(
                                  context,
                                  '/medecin/prescription_details',
                                  arguments: prescription.id,
                                );
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('Voir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.medicalBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.medicalBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
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