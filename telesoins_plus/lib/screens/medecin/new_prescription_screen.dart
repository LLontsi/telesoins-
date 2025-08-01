import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/prescription.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';

class NewPrescriptionScreen extends StatefulWidget {
  final int? patientId; // Optionnel - si vient d'un patient spécifique

  const NewPrescriptionScreen({Key? key, this.patientId}) : super(key: key);

  @override
  State<NewPrescriptionScreen> createState() => _NewPrescriptionScreenState();
}

class _NewPrescriptionScreenState extends State<NewPrescriptionScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  Patient? _selectedPatient;
  List<Patient> _patients = [];
  List<MedicationItem> _medications = [MedicationItem()];
  
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _patientSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _instructionsController.dispose();
    _patientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Appel API réel pour charger les patients
      // _patients = await _consultationService.getPatients();

      // Pour les tests
      await Future.delayed(const Duration(milliseconds: 800));
      _patients = [
        Patient(
          id: 1,
          firstName: 'Marie',
          lastName: 'Dupont',
          email: 'marie.dupont@example.com',
          phoneNumber: '+33 6 12 34 56 78',
          dateOfBirth: DateTime(1985, 5, 12),
        ),
        Patient(
          id: 2,
          firstName: 'Jean',
          lastName: 'Martin',
          email: 'jean.martin@example.com',
          phoneNumber: '+33 6 23 45 67 89',
          dateOfBirth: DateTime(1978, 9, 23),
        ),
        Patient(
          id: 3,
          firstName: 'Sophie',
          lastName: 'Bernard',
          email: 'sophie.bernard@example.com',
          phoneNumber: '+33 6 34 56 78 90',
          dateOfBirth: DateTime(1990, 3, 8),
        ),
        Patient(
          id: 4,
          firstName: 'Pierre',
          lastName: 'Dubois',
          email: 'pierre.dubois@example.com',
          phoneNumber: '+33 6 45 67 89 01',
          dateOfBirth: DateTime(1965, 11, 30),
        ),
      ];
      
      // Si un patientId a été fourni, sélectionner le patient correspondant
      if (widget.patientId != null) {
        _selectedPatient = _patients.firstWhere(
          (patient) => patient.id == widget.patientId,
          orElse: () => _patients.first,
        );
      }
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

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate() || _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Préparer les médicaments
      final medications = _medications
          .where((med) => med.name.isNotEmpty && med.dosage.isNotEmpty)
          .map((med) => Medication(
                name: med.name,
                dosage: med.dosage,
                frequency: med.frequency,
                durationDays: med.duration,
                specialInstructions: med.instructions,
              ))
          .toList();
      
      if (medications.isEmpty) {
        throw 'Veuillez ajouter au moins un médicament';
      }
      
      // TODO: Appel API pour enregistrer la prescription
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulation d'une réponse réussie
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription créée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Retour à l'écran précédent
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationItem());
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Nouvelle Ordonnance',
        type: AppBarType.medecin,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorDisplay(
                  message: 'Erreur',
                  details: _errorMessage,
                  onRetry: _loadPatients,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patient',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_selectedPatient != null)
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryColor,
                                      child: Text(
                                        _getInitials(_selectedPatient!.fullName),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(_selectedPatient!.fullName),
                                    subtitle: Text(
                                      _selectedPatient!.dateOfBirth != null
                                          ? '${_calculateAge(_selectedPatient!.dateOfBirth!)} ans'
                                          : 'Patient',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _selectedPatient = null;
                                        });
                                      },
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      TextField(
                                        controller: _patientSearchController,
                                        decoration: const InputDecoration(
                                          hintText: 'Rechercher un patient',
                                          prefixIcon: Icon(Icons.search),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          // Filtrer les patients selon la recherche
                                          setState(() {});
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        constraints: const BoxConstraints(maxHeight: 200),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _patients.length,
                                          itemBuilder: (context, index) {
                                            final patient = _patients[index];
                                            final search = _patientSearchController.text.toLowerCase();
                                            
                                            if (search.isNotEmpty &&
                                                !patient.fullName.toLowerCase().contains(search)) {
                                              return const SizedBox.shrink();
                                            }
                                            
                                            return ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: AppTheme.primaryColor,
                                                child: Text(
                                                  _getInitials(patient.fullName),
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ),
                                              title: Text(patient.fullName),
                                              subtitle: Text(
                                                patient.dateOfBirth != null
                                                    ? '${_calculateAge(patient.dateOfBirth!)} ans'
                                                    : 'Patient',
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  _selectedPatient = patient;
                                                  _patientSearchController.clear();
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Diagnostic',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _diagnosisController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Entrez le diagnostic',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer un diagnostic';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Médicaments',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _addMedication,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Ajouter'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._medications.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final medication = entry.value;
                                  
                                  return _buildMedicationForm(medication, index);
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Instructions supplémentaires',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _instructionsController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Entrez des instructions supplémentaires',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _savePrescription,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Text(
                                    'Créer l\'ordonnance',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMedicationForm(MedicationItem medication, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Médicament #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_medications.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeMedication(index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: medication.name,
            decoration: const InputDecoration(
              labelText: 'Nom du médicament *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le nom du médicament';
              }
              return null;
            },
            onChanged: (value) {
              medication.name = value;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: medication.dosage,
                  decoration: const InputDecoration(
                    labelText: 'Dosage *',
                    border: OutlineInputBorder(),
                    hintText: 'ex: 500mg',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    medication.dosage = value;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: medication.frequency,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence *',
                    border: OutlineInputBorder(),
                    hintText: 'ex: 3x/jour',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    medication.frequency = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: medication.duration > 0 ? medication.duration.toString() : '',
            decoration: const InputDecoration(
              labelText: 'Durée (jours) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer la durée';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Entrez un nombre valide';
              }
              return null;
            },
            onChanged: (value) {
              medication.duration = int.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: medication.instructions,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Instructions spécifiques',
              border: OutlineInputBorder(),
              hintText: 'ex: À prendre avant les repas',
            ),
            onChanged: (value) {
              medication.instructions = value;
            },
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

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}

class MedicationItem {
  String name = '';
  String dosage = '';
  String frequency = '';
  int duration = 0;
  String instructions = '';
  
  MedicationItem({
    this.name = '',
    this.dosage = '',
    this.frequency = '',
    this.duration = 0,
    this.instructions = '',
  });
}