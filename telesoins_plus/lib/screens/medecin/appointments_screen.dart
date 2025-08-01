import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/appointment.dart';
import 'package:telesoins_plus/services/consultation_service.dart';
import 'package:telesoins_plus/widgets/common/app_bar.dart';
import 'package:telesoins_plus/widgets/common/nav_drawer.dart';
import 'package:telesoins_plus/widgets/common/loading_indicator.dart';
import 'package:telesoins_plus/widgets/common/error_display.dart';
import 'package:telesoins_plus/widgets/appointment_card.dart';
import 'package:telesoins_plus/utils/date_formatter.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  final ConsultationService _consultationService = ConsultationService();
  bool _isLoading = false;
  String? _errorMessage;
  List<Appointment> _appointments = [];
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
    _generateAvailableDates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateAvailableDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    _availableDates = List.generate(
      14, // 2 semaines
      (index) => today.add(Duration(days: index)),
    );
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _consultationService.getAppointments();
      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les rendez-vous: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Appointment> _getAppointmentsForDate(DateTime date) {
    return _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      final selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
      );
      return appointmentDate == selectedDate;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> _getPendingAppointments() {
    return _appointments
        .where((appointment) => appointment.status == AppointmentStatus.pending)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> _getUrgentAppointments() {
    return _appointments
        .where((appointment) => appointment.isUrgent)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestion des Rendez-vous',
        type: AppBarType.medecin,
      ),
      drawer: const NavDrawer(activeRoute: '/medecin/appointments'),
      body: Column(
        children: [
          // Sélecteur de date
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppTheme.medicalBlue.withOpacity(0.05),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatDate(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Changer'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableDates.length,
                    itemBuilder: (context, index) {
                      final date = _availableDates[index];
                      final isSelected = DateUtils.isSameDay(date, _selectedDate);
                      final isToday = DateUtils.isSameDay(date, DateTime.now());
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.medicalBlue
                                : isToday
                                    ? AppTheme.medicalBlue.withOpacity(0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected || isToday
                                  ? AppTheme.medicalBlue
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E', 'fr').format(date)[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? AppTheme.medicalBlue
                                          : AppTheme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? AppTheme.medicalBlue
                                          : AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.medicalBlue,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.medicalBlue,
            tabs: const [
              Tab(text: 'Journée'),
              Tab(text: 'En attente'),
              Tab(text: 'Urgents'),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _errorMessage != null
                    ? ErrorDisplay(
                        message: 'Erreur de chargement',
                        details: _errorMessage,
                        onRetry: _loadAppointments,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Onglet des rendez-vous du jour sélectionné
                            _buildAppointmentsList(
                              _getAppointmentsForDate(_selectedDate),
                              emptyMessage: 'Aucun rendez-vous pour cette date',
                            ),
                            
                            // Onglet des rendez-vous en attente
                            _buildAppointmentsList(
                              _getPendingAppointments(),
                              emptyMessage: 'Aucun rendez-vous en attente',
                            ),
                            
                            // Onglet des rendez-vous urgents
                            _buildAppointmentsList(
                              _getUrgentAppointments(),
                              emptyMessage: 'Aucun rendez-vous urgent',
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments, {required String emptyMessage}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentCard(
          appointment: appointment,
          isPatientView: false, // Vue médecin
          onTap: () {
            Navigator.pushNamed(
              context,
              '/medecin/appointment_details',
              arguments: appointment.id,
            );
          },
          onCancel: appointment.status == AppointmentStatus.pending ||
                  appointment.status == AppointmentStatus.confirmed
              ? () {
                  _showCancelDialog(appointment);
                }
              : null,
        );
      },
    );
  }

  Future<void> _showCancelDialog(Appointment appointment) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler le rendez-vous'),
          content: const Text(
            'Êtes-vous sûr de vouloir annuler ce rendez-vous ? Le patient sera notifié.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  setState(() {
                    _isLoading = true;
                  });
                  await _consultationService.cancelAppointment(appointment.id);
                  // Recharger les rendez-vous
                  await _loadAppointments();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rendez-vous annulé avec succès'),
                        backgroundColor: AppTheme.successColor,
                      ),
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
                    _isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );
  }
}