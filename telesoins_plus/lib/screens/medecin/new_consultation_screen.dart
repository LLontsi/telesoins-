import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';

class NewConsultationScreen extends StatefulWidget {
  final int? patientId; // Optionnel - si vient d'un patient spécifique

  const NewConsultationScreen({Key? key, this.patientId}) : super(key: key);

  @override
  State<NewConsultationScreen> createState() => _NewConsultationScreenState();
}

class _NewConsultationScreenState extends State<NewConsultationScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  Patient? _selectedPatient;
  List<Patient> _patients = [];
  
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _patientSearchController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedConsultationType = 'Video';
  int _selectedDuration = 30; // minutes

  final List<String> _consultationTypes = ['Video', 'Message', 'Téléphone'];
  final List<int> _consultationDurations = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('fr', 'FR'),
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _scheduleConsultation() async {
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
      // Combiner date et heure
      final consultationDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // TODO: Appel API pour programmer la consultation
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulation d'une réponse réussie
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation programmée avec succès'),
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd('fr');
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Nouvelle Consultation',
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
                                  'Détails de la consultation',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        readOnly: true,
                                        controller: TextEditingController(
                                          text: dateFormat.format(_selectedDate),
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'Date',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.calendar_today),
                                        ),
                                        onTap: () => _selectDate(context),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        readOnly: true,
                                        controller: TextEditingController(
                                          text: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'Heure',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.access_time),
                                        ),
                                        onTap: () => _selectTime(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedConsultationType,
                                        decoration: const InputDecoration(
                                          labelText: 'Type de consultation',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _consultationTypes.map((type) {
                                          return DropdownMenuItem<String>(
                                            value: type,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  type == 'Video'
                                                      ? Icons.videocam
                                                      : type == 'Message'
                                                          ? Icons.message
                                                          : Icons.phone,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(type),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedConsultationType = value!;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _selectedDuration,
                                        decoration: const InputDecoration(
                                          labelText: 'Durée (minutes)',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _consultationDurations.map((duration) {
                                          return DropdownMenuItem<int>(
                                            value: duration,
                                            child: Text('$duration min'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedDuration = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _reasonController,
                                  decoration: const InputDecoration(
                                    labelText: 'Motif de la consultation *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer le motif de la consultation';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes additionnelles',
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
                            onPressed: _isSubmitting ? null : _scheduleConsultation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Text(
                                    'Programmer la consultation',
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