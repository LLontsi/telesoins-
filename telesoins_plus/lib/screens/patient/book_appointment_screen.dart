import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({Key? key}) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isUrgent = false;
  String _appointmentType = 'video';
  String? _reasonForVisit;
  DateTime? _selectedDate;
  String? _selectedTime;
  Medecin? _selectedMedecin;
  List<Medecin> _availableMedecins = [];
  List<String> _availableTimes = [];
  
  @override
  void initState() {
    super.initState();
    _loadMedecins();
  }
  
  Future<void> _loadMedecins() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Remplacer par un appel API réel
      // Simulation de médecins pour l'exemple
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _availableMedecins = List.generate(
          5,
          (index) => Medecin(
            id: index + 1,
            email: 'medecin${index + 1}@example.com',
            firstName: 'Dr. Prénom${index + 1}',
            lastName: 'Nom${index + 1}',
            phoneNumber: '+33 6 12 34 56 78',
            speciality: ['Généraliste', 'Cardiologue', 'Dermatologue', 'Pédiatre', 'Psychiatre'][index],
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des médecins: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _updateAvailableTimes() {
    if (_selectedDate == null || _selectedMedecin == null) {
      setState(() {
        _availableTimes = [];
        _selectedTime = null;
      });
      return;
    }
    
    // Générer des créneaux disponibles (simulés)
    final List<String> times = [];
    final now = DateTime.now();
    final isToday = _selectedDate!.year == now.year && 
                   _selectedDate!.month == now.month && 
                   _selectedDate!.day == now.day;
    
    int startHour = isToday ? (now.hour + 1) : 8;
    startHour = startHour < 8 ? 8 : startHour;
    
    for (int hour = startHour; hour <= 18; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        // Sauter les créneaux déjà passés si c'est aujourd'hui
        if (isToday && hour == now.hour && minute <= now.minute) {
          continue;
        }
        times.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    
    setState(() {
      _availableTimes = times;
      _selectedTime = times.isNotEmpty ? times.first : null;
    });
  }
  
  Future<void> _selectDate() async {
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 60)),
      onConfirm: (date) {
        setState(() {
          _selectedDate = date;
        });
        _updateAvailableTimes();
      },
      currentTime: _selectedDate ?? DateTime.now(),
      locale: LocaleType.fr,
    );
  }
  
  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null || _selectedMedecin == null) {
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
      // Préparer la date et l'heure du rendez-vous
      final timeParts = _selectedTime!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );
      
      // Créer le rendez-vous
      final appointmentData = {
        'medecin_id': _selectedMedecin!.id,
        'date_time': appointmentDateTime.toIso8601String(),
        'reason_for_visit': _reasonForVisit,
        'is_urgent': _isUrgent,
        'appointment_type': _appointmentType,
      };
      
      await _consultationService.createAppointment(appointmentData);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous pris avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pushReplacementNamed(context, '/patient/appointments');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de rendez-vous: ${e.toString()}'),
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
      appBar: const CustomAppBar(
        title: 'Prendre rendez-vous',
        type: AppBarType.patient,
      ),
      body: _isLoading 
          ? const LoadingIndicator() 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type de rendez-vous
                    const Text(
                      'Type de consultation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAppointmentTypeSelector(),
                    const SizedBox(height: 24),
                    
                    // Sélection du médecin
                    const Text(
                      'Sélectionnez un médecin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMedecinSelector(),
                    const SizedBox(height: 24),
                    
                    // Date et heure
                    const Text(
                      'Date et heure',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_selectedDate == null 
                              ? 'Sélectionner une date' 
                              : DateFormat.yMMMMd('fr').format(_selectedDate!)),
                            onPressed: _selectDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTime,
                            decoration: const InputDecoration(
                              labelText: 'Heure',
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            items: _availableTimes.map((time) {
                              return DropdownMenuItem<String>(
                                value: time,
                                child: Text(time),
                              );
                            }).toList(),
                            onChanged: _availableTimes.isEmpty 
                                ? null 
                                : (value) {
                                    setState(() {
                                      _selectedTime = value;
                                    });
                                  },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Sélectionnez une heure';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDate != null && _availableTimes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Aucun créneau disponible à cette date. Veuillez sélectionner une autre date.',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Motif de consultation
                    const Text(
                      'Motif de consultation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Décrivez brièvement le motif de votre consultation',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {
                          _reasonForVisit = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez indiquer le motif de votre consultation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Urgence
                    SwitchListTile(
                      title: const Text(
                        'Consultation urgente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Cochez cette case si votre problème nécessite une attention rapide',
                      ),
                      value: _isUrgent,
                      activeColor: AppTheme.urgentColor,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value;
                        });
                      },
                      secondary: const Icon(
                        Icons.warning,
                        color: AppTheme.urgentColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Bouton de validation
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _bookAppointment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('CONFIRMER LE RENDEZ-VOUS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildAppointmentTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _appointmentType = 'video';
              });
            },
            child: Card(
              color: _appointmentType == 'video' 
                  ? AppTheme.primaryColor.withOpacity(0.1) 
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _appointmentType == 'video' 
                      ? AppTheme.primaryColor 
                      : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(
                      Icons.videocam,
                      color: _appointmentType == 'video' 
                          ? AppTheme.primaryColor 
                          : AppTheme.textSecondaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text('Vidéo'),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _appointmentType = 'chat';
              });
            },
            child: Card(
              color: _appointmentType == 'chat' 
                  ? AppTheme.primaryColor.withOpacity(0.1) 
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _appointmentType == 'chat' 
                      ? AppTheme.primaryColor 
                      : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat,
                      color: _appointmentType == 'chat' 
                          ? AppTheme.primaryColor 
                          : AppTheme.textSecondaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text('Message'),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _appointmentType = 'sms';
              });
            },
            child: Card(
              color: _appointmentType == 'sms' 
                  ? AppTheme.primaryColor.withOpacity(0.1) 
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _appointmentType == 'sms' 
                      ? AppTheme.primaryColor 
                      : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(
                      Icons.sms,
                      color: _appointmentType == 'sms' 
                          ? AppTheme.primaryColor 
                          : AppTheme.textSecondaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text('SMS'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMedecinSelector() {
    return DropdownButtonFormField<Medecin>(
      value: _selectedMedecin,
      decoration: const InputDecoration(
        labelText: 'Médecin',
        prefixIcon: Icon(Icons.person),
      ),
      items: _availableMedecins.map((medecin) {
        return DropdownMenuItem<Medecin>(
          value: medecin,
          child: Text('Dr. ${medecin.lastName} - ${medecin.speciality}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedMedecin = value;
        });
        _updateAvailableTimes();
      },
      validator: (value) {
        if (value == null) {
          return 'Veuillez sélectionner un médecin';
        }
        return null;
      },
    );
  }
}