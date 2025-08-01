import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:telesoins_plus2/config/api_constants.dart';
import 'package:telesoins_plus2/config/theme.dart';
import 'package:telesoins_plus2/main.dart';
import 'package:telesoins_plus2/models/user.dart';
import 'package:telesoins_plus2/services/api_service.dart';
import 'package:telesoins_plus2/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({Key? key}) : super(key: key);

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final ApiService _apiService = getIt<ApiService>();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  List<User> _medecins = [];
  
  User? _selectedMedecin;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isUrgent = false;
  
  @override
  void initState() {
    super.initState();
    _loadMedecins();
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMedecins() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _apiService.get('/api/medecins/');
      
      if (mounted) {
        setState(() {
          _medecins = (response as List)
              .map((item) => User.fromJson(item))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des médecins: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedMedecin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un médecin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      final data = {
        'medecin': _selectedMedecin!.id,
        'datetime': dateTime.toIso8601String(),
        'reason': _reasonController.text,
        'notes': _notesController.text,
        'is_urgent': _isUrgent,
      };
      
      await _apiService.post(ApiConstants.appointments, data: data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du rendez-vous: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prendre rendez-vous'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélection du médecin
                    const Text(
                      'Choisir un médecin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<User>(
                      decoration: const InputDecoration(
                        hintText: 'Sélectionnez un médecin',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _medecins.map((medecin) {
                        return DropdownMenuItem<User>(
                          value: medecin,
                          child: Text('Dr. ${medecin.lastName} ${medecin.firstName}'),
                        );
                      }).toList(),
                      value: _selectedMedecin,
                      onChanged: (value) {
                        setState(() {
                          _selectedMedecin = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un médecin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Date et heure
                    const Text(
                      'Date et heure',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today),
                                labelText: 'Date',
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.access_time),
                                labelText: 'Heure',
                              ),
                              child: Text(
                                _selectedTime.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Motif
                    const Text(
                      'Motif de consultation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Fièvre, douleurs abdominales...',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez indiquer le motif de consultation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes
                    const Text(
                      'Notes additionnelles (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Informations complémentaires...',
                        prefixIcon: Icon(Icons.note_outlined),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Urgence
                    CheckboxListTile(
                      title: const Text(
                        'Demande urgente',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Cochez cette case si votre situation nécessite une attention rapide',
                      ),
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 32),
                    
                    // Bouton de soumission
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitAppointment,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirmer le rendez-vous'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}