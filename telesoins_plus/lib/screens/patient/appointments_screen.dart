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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  List<Appointment> _getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((appointment) =>
            (appointment.status == AppointmentStatus.confirmed ||
                appointment.status == AppointmentStatus.pending) &&
            appointment.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> _getPastAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((appointment) =>
            (appointment.status == AppointmentStatus.completed ||
                appointment.status == AppointmentStatus.cancelled ||
                appointment.status == AppointmentStatus.missed) ||
            (appointment.status == AppointmentStatus.confirmed &&
                appointment.dateTime.isBefore(now)))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Trier du plus récent au plus ancien
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mes Rendez-vous',
        type: AppBarType.patient,
      ),
      drawer: const NavDrawer(activeRoute: '/patient/appointments'),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'À venir'),
              Tab(text: 'Passés'),
              Tab(text: 'Tous'),
            ],
          ),
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
                            // Onglet des rendez-vous à venir
                            _buildAppointmentsList(
                              _getUpcomingAppointments(),
                              emptyMessage: 'Aucun rendez-vous à venir',
                            ),
                            // Onglet des rendez-vous passés
                            _buildAppointmentsList(
                              _getPastAppointments(),
                              emptyMessage: 'Aucun rendez-vous passé',
                            ),
                            // Onglet de tous les rendez-vous
                            _buildAppointmentsList(
                              _appointments,
                              emptyMessage: 'Aucun rendez-vous',
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/patient/book_appointment');
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
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
              Icons.calendar_today,
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/patient/book_appointment');
              },
              icon: const Icon(Icons.add),
              label: const Text('Prendre rendez-vous'),
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
          onTap: () {
            Navigator.pushNamed(
              context,
              '/patient/appointment_details',
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
            'Êtes-vous sûr de vouloir annuler ce rendez-vous ? Cette action ne peut pas être annulée.',
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