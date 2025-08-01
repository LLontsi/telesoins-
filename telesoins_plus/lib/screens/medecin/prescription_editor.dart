import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/prescription.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';

class PrescriptionEditorScreen extends StatefulWidget {
  final int? patientId;
  final int? prescriptionId; // null pour une nouvelle prescription, sinon édition

  const PrescriptionEditorScreen({
    Key? key,
    this.patientId,
    this.prescriptionId,
  }) : super(key: key);

  @override
  State<PrescriptionEditorScreen> createState() => _PrescriptionEditorScreenState();
}

class _PrescriptionEditorScreenState extends State<PrescriptionEditorScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isEditing = false;
  Patient? _patient;
  List<Medication> _medications = [];
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _additionalInstructionsController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _isEditing = widget.prescriptionId != null;
    _loadData();
  }
  
  @override
  void dispose() {
    _diagnosisController.dispose();
    _additionalInstructionsController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.patientId != null) {
        // Chargement des données du patient pour une nouvelle prescription
        // TODO: Appel API réel
        await Future.delayed(const Duration(seconds: 1));
        
        _patient = Patient(
          id: widget.patientId!,
          email: 'patient${widget.patientId}@example.com',
          firstName: 'Prénom',
          lastName: 'Nom',
          phoneNumber: '+33 6 12 34 56 78',
        );
        
        // Ajouter un médicament vide par défaut
        _medications.add(Medication(
          name: '',
          dosage: '',
          frequency: '',
          durationDays: 7,
        ));
      } else if (widget.prescriptionId != null) {
        // Chargement d'une prescription existante pour édition
        // TODO: Appel API réel
        await Future.delayed(const Duration(seconds: 1));
        
        // Simuler les données d'une prescription existante
        final prescription = Prescription(
          id: widget.prescriptionId!,
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
          issueDate: DateTime.now().subtract(const Duration(days: 2)),
          expiryDate: DateTime.now().add(const Duration(days: 28)),
          medications: [
            Medication(
              name: 'Paracétamol',
              dosage: '1000mg',
              frequency: '3x par jour',
              durationDays: 7,
              specialInstructions: 'Prendre pendant les repas',
            ),
            Medication(
              name: 'Ibuprofène',
              dosage: '400mg',
              frequency: '2x par jour',
              durationDays: 5,
            ),
          ],
          diagnosis: 'Migraine et douleurs musculaires',
          additionalInstructions: 'Repos conseillé pendant 48h',
        );
        
        // Mettre à jour l'état avec les données chargées
        _patient = prescription.patient;
        _medications = prescription.medications;
        _diagnosisController.text = prescription.diagnosis ?? '';
        _additionalInstructionsController.text = prescription.additionalInstructions ?? '';
        _expiryDate = prescription.expiryDate;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addMedication() {
    setState(() {
      _medications.add(Medication(
        name: '',
        dosage: '',
        frequency: '',
        durationDays: 7,
      ));
    });
  }
  
  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }
  
  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate() || _patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Préparer les données de la prescription
      final prescriptionData = {
        'patient_id': _patient!.id,
        'medications': _medications.map((med) => {
          'name': med.name,
          'dosage': med.dosage,
          'frequency': med.frequency,
          'duration_days': med.durationDays,
          'special_instructions': med.specialInstructions,
        }).toList(),
        'diagnosis': _diagnosisController.text,
        'additional_instructions': _additionalInstructionsController.text,
        'expiry_date': _expiryDate.toIso8601String(),
      };
      
      if (_isEditing) {
        // Mettre à jour une prescription existante
        // TODO: Implémentation réelle
        await Future.delayed(const Duration(seconds: 1));
      } else {
        // Créer une nouvelle prescription
        await _consultationService.createPrescription(prescriptionData);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Ordonnance modifiée avec succès' 
                : 'Ordonnance créée avec succès'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Modifier l\'ordonnance' : 'Nouvelle ordonnance',
        type: AppBarType.medecin,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _patient == null
              ? const Center(
                  child: Text('Patient introuvable'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informations patient
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patient',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.medicalBlue,
                                      child: Text(
                                        _getInitials('${_patient!.firstName} ${_patient!.lastName}'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_patient!.firstName} ${_patient!.lastName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _patient!.phoneNumber,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Diagnostic
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Diagnostic',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Divider(),
                                TextFormField(
                                  controller: _diagnosisController,
                                  decoration: const InputDecoration(
                                    hintText: 'Entrez le diagnostic',
                                  ),
                                  maxLines: 2,
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
                        const SizedBox(height: 16),
                        
                        // Médicaments
                        Card(
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _addMedication,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Ajouter'),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                ..._medications.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final medication = entry.value;
                                  return _buildMedicationField(index, medication);
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Instructions supplémentaires
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Instructions supplémentaires',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Divider(),
                                TextFormField(
                                  controller: _additionalInstructionsController,
                                  decoration: const InputDecoration(
                                    hintText: 'Instructions ou conseils pour le patient',
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Date d'expiration
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date d\'expiration',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Divider(),
                                ListTile(
                                  title: Text(
                                    'Valable jusqu\'au ${DateFormat.yMMMMd('fr').format(_expiryDate)}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: _selectExpiryDate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Annuler'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _savePrescription,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.medicalBlue,
                                ),
                                child: Text(_isEditing ? 'Mettre à jour' : 'Créer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildMedicationField(int index, Medication medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Médicament ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_medications.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: AppTheme.errorColor,
                  onPressed: () => _removeMedication(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: medication.name,
            decoration: const InputDecoration(
              labelText: 'Nom du médicament',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le nom du médicament';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _medications[index] = Medication(
                  name: value,
                  dosage: medication.dosage,
                  frequency: medication.frequency,
                  durationDays: medication.durationDays,
                  specialInstructions: medication.specialInstructions,
                );
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: medication.dosage,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Dosage requis';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _medications[index] = Medication(
                        name: medication.name,
                        dosage: value,
                        frequency: medication.frequency,
                        durationDays: medication.durationDays,
                        specialInstructions: medication.specialInstructions,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: medication.frequency,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Fréquence requise';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _medications[index] = Medication(
                        name: medication.name,
                        dosage: medication.dosage,
                        frequency: value,
                        durationDays: medication.durationDays,
                        specialInstructions: medication.specialInstructions,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: medication.durationDays,
                  decoration: const InputDecoration(
                    labelText: 'Durée (jours)',
                    border: OutlineInputBorder(),
                  ),
                  items: [3, 5, 7, 10, 14, 21, 28, 30].map((days) {
                    return DropdownMenuItem<int>(
                      value: days,
                      child: Text('$days jours'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _medications[index] = Medication(
                        name: medication.name,
                        dosage: medication.dosage,
                        frequency: medication.frequency,
                        durationDays: value!,
                        specialInstructions: medication.specialInstructions,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: medication.specialInstructions,
            decoration: const InputDecoration(
              labelText: 'Instructions spéciales (optionnel)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _medications[index] = Medication(
                  name: medication.name,
                  dosage: medication.dosage,
                  frequency: medication.frequency,
                  durationDays: medication.durationDays,
                  specialInstructions: value,
                );
              });
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
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