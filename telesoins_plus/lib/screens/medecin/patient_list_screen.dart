import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/nav_drawer.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Patient> _patients = [];
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Remplacer par un appel API réel
      // Simulation de patients pour l'exemple
      await Future.delayed(const Duration(seconds: 1));
      _patients = List.generate(
        20,
        (index) => Patient(
          id: index + 1,
          email: 'patient${index + 1}@example.com',
          firstName: 'Prénom${index + 1}',
          lastName: 'Nom${index + 1}',
          phoneNumber: '+33 6 12 34 56 78',
          dateOfBirth: DateTime(1980 + (index % 30), 1 + (index % 12), 1 + (index % 28)),
          address: 'Adresse du patient ${index + 1}',
          bloodGroup: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'][index % 8],
        ),
      );
      
      _filteredPatients = List.from(_patients);
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger la liste des patients: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_patients);
      } else {
        _filteredPatients = _patients
            .where((patient) =>
                patient.firstName.toLowerCase().contains(query.toLowerCase()) ||
                patient.lastName.toLowerCase().contains(query.toLowerCase()) ||
                patient.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes Patients',
        type: AppBarType.medecin,
      ),
      drawer: const NavDrawer(activeRoute: '/medecin/patients'),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un patient...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterPatients('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterPatients,
            ),
          ),
          // Liste des patients
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _errorMessage != null
                    ? ErrorDisplay(
                        message: 'Erreur de chargement',
                        details: _errorMessage,
                        onRetry: _loadPatients,
                      )
                    : _filteredPatients.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun patient trouvé',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPatients,
                            child: ListView.builder(
                              itemCount: _filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = _filteredPatients[index];
                                return _buildPatientCard(patient);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/medecin/patient_details',
            arguments: patient.id,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar du patient
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.medicalBlue,
                backgroundImage: patient.profilePhotoUrl != null
                    ? NetworkImage(patient.profilePhotoUrl!)
                    : null,
                child: patient.profilePhotoUrl == null
                    ? Text(
                        _getInitials('${patient.firstName} ${patient.lastName}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Informations du patient
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${patient.firstName} ${patient.lastName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Né(e) le ${_formatDate(patient.dateOfBirth)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.bloodtype,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Groupe sanguin: ${patient.bloodGroup ?? 'Non renseigné'}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Icône de navigation
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non renseigné';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}